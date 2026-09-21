# Chromium web apps on the personal (Default) profile. The explicit
# --profile-directory stops Chromium from opening the last-used profile.
{
  xdg.desktopEntries = {
    youtube = {
      name = "YouTube";
      exec = "chromium --profile-directory=Default --app=https://www.youtube.com";
      icon = ./webapps/youtube.png;
    };
    brainfm = {
      name = "Brain.fm";
      exec = "chromium --profile-directory=Default --app=https://my.brain.fm";
      icon = ./webapps/brainfm.png;
    };
    whatsapp = {
      name = "WhatsApp";
      exec = "chromium --profile-directory=Default --app=https://web.whatsapp.com";
      icon = ./webapps/whatsapp.png;
    };
  };
}
