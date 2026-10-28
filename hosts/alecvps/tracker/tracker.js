import { serve } from "bun";
import { Database } from "bun:sqlite";
import { connect } from "net";
import { resolveSrv } from "dns/promises";

const servers = {
  mh: "nocturnmh.minehut.gg",
  mk: "nocturn.minekeep.gg"
};
const pollInterval = 60_000;
const pingTimeout = 15_000;
const maxPlayers = 32; // higher counts are bogus data

const db = new Database("/var/lib/nocturn-tracker/tracker.db");

db.run("PRAGMA journal_mode = WAL"); // survive unclean restarts
db.run(`
  CREATE TABLE IF NOT EXISTS samples (
    timestamp INTEGER PRIMARY KEY,
    mh INTEGER,
    mk INTEGER
  );
`);

const insert = db.prepare("INSERT OR REPLACE INTO samples (timestamp, mh, mk) VALUES (?, ?, ?)");
const getData = db.prepare(`
  SELECT
    timestamp,
    CASE WHEN mh <= $max THEN mh END AS mh,
    CASE WHEN mk <= $max THEN mk END AS mk
  FROM samples
  WHERE timestamp >= $since
  ORDER BY timestamp ASC
`);

// Java server list ping: https://minecraft.wiki/w/Java_Edition_protocol/Server_List_Ping
const varint = (n) => {
  const out = [];
  do {
    out.push((n & 0x7f) | (n >>> 7 ? 0x80 : 0));
    n >>>= 7;
  } while (n);
  return out;
};
const packet = (...fields) => {
  const body = fields.flat();
  return Buffer.from([ ...varint(body.length), ...body ]);
};
const readVarint = (buf, pos) => { // [ value, next pos ], or null if incomplete
  for (let n = 0, shift = 0; pos < buf.length; shift += 7) {
    const b = buf[pos++];
    n |= (b & 0x7f) << shift;
    if (!(b & 0x80)) return [ n, pos ];
  };
  return null;
};

async function ping(host) {
  let port = 25565;
  try { ({ name: host, port } = (await resolveSrv(`_minecraft._tcp.${host}`))[0]); } catch {};

  return new Promise((resolve) => {
    let buf = Buffer.alloc(0);
    const sock = connect(port, host, () => {
      const name = [ ...Buffer.from(host) ];
      sock.write(Buffer.concat([
        packet(0x00, varint(47), varint(name.length), name, port >> 8, port & 0xff, 0x01), // handshake, next state: status
        packet(0x00) // status request
      ]));
    });
    const done = (online) => {
      clearTimeout(timer);
      sock.destroy();
      resolve(online);
    };
    const timer = setTimeout(() => done(null), pingTimeout);

    sock.on("error", () => done(null));
    sock.on("close", () => done(null));
    sock.on("data", (chunk) => {
      buf = Buffer.concat([ buf, chunk ]);
      const len = readVarint(buf, 0);
      if (!len || buf.length < len[1] + len[0]) return;

      try {
        const [ , strPos ] = readVarint(buf, len[1]); // packet id
        const [ strLen, jsonPos ] = readVarint(buf, strPos);
        const online = JSON.parse(buf.toString("utf8", jsonPos, jsonPos + strLen)).players.online;
        done(online <= maxPlayers ? online : null);
      } catch {
        done(null);
      };
    });
  });
};

async function poll() {
  const [ mh, mk ] = await Promise.all([ ping(servers.mh), ping(servers.mk) ]);
  insert.run(Date.now(), mh, mk);
};

poll();
setInterval(poll, pollInterval);

const page = await Bun.file(import.meta.dir + "/page.html").text();

serve({
  port: 80,
  hostname: "::", // Cloudflare reaches the origin over IPv6
  fetch(req) {
    const pathname = new URL(req.url).pathname;

    if (pathname.startsWith("/getdata")) {
      const span = (pathname == "/getdata")
        ? 86400000 // past 24 hours
        : 604800000; // past 7 days

      const body = {
        samples: getData.all({ $max: maxPlayers, $since: Date.now() - span })
      };
      return new Response(JSON.stringify(body), {
        headers: { "Content-Type": "application/json" }
      });
    };

    return new Response(page, { headers: { "Content-Type": "text/html" }});
  }
});
