{ config, ... }:
let
  hostSpec = config.hostSpec;
  email = hostSpec.email;
in
{
  introdus.mail-delivery = rec {
    enable = true;
    #FIXME: revisit this if I add a relay at some point.
    # useRelay = hostSpec.isLocal && (!hostSpec.isRoaming);
    useRelay = false;
    emailFrom = email.notifier;
    smtpHost = if useRelay then email.internalServer else email.externalServer;
    smtpPort = if useRelay then 25 else 587;
    smtpUser = if useRelay then hostSpec.hostName else email.notifier;
  };
}
