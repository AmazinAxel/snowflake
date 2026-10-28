let
  speaker = { "device.name" = "bluez_card.67_10_1D_B6_4C_E2"; };
  earbuds = { "device.name" = "bluez_card.D6_1F_21_FC_F9_C7"; };
in {
  # loads after borealis' 51-bluetooth-hifi, so these rules win
  services.pipewire.wireplumber.extraConfig."52-bluetooth-devices" = {
    "device.profile.priority.rules" = [
      { # drops packets or is wonky on 452kbps!!! :p
        matches = [ speaker earbuds ];
        actions.update-props.priorities = [ "a2dp-sink" ];
      }
      { # Rail ANC
        matches = [{ "device.name" = "bluez_card.88_08_94_2F_FB_D2"; }];
        actions.update-props.priorities = [ "a2dp-sink-aac" "a2dp-sink-sbc_xq" "a2dp-sink" ];
      }
    ];

    "monitor.bluez.rules" = [
      { # BLUETOOTH SPEAKER
        matches = [ speaker ];
        actions.update-props."device.description" = "Bluetooth Speaker";
      } { # BLUETOOTH EARBUDS
        matches = [ earbuds ];
        actions.update-props."device.description" = "Bluetooth Earbuds";
      }
    ];
  };
}
