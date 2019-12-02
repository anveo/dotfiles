alias nothankyouadobe='
sudo -H killall ACCFinderSync \"Core Sync\" AdobeCRDaemon \"Adobe Creative\" AdobeIPCBroker node \"Adobe Desktop Service\" \"Adobe Crash Reporter\";
sudo -H rm -rf \"/Library/LaunchAgents/com.adobe.AAM.Updater-1.0.plist\" \"/Library/LaunchAgents/com.adobe.AdobeCreativeCloud.plist\" \"/Library/LaunchDaemons/com.adobe.*.plist\"
'

alias nothankyouadobe='
sudo -H killall
  ACCFinderSync
  \"Core Sync\"
  AdobeCRDaemon
  \"Adobe Creative\"
  AdobeIPCBroker
  node
  \"Adobe Desktop Service\"
  \"Adobe Crash Reporter\";
sudo -H rm -rf
  \"/Library/LaunchAgents/com.adobe.AAM.Updater-1.0.plist\"
  \"/Library/LaunchAgents/com.adobe.AdobeCreativeCloud.plist\"
  \"/Library/LaunchDaemons/com.adobe.*.plist\"
'
