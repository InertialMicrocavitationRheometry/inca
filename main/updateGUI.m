% Create a new ToolGroup ("app") with a hidden DataBrowser
import matlab.ui.internal.toolstrip.*  % for convenience below

hToolGroup = matlab.ui.internal.desktop.ToolGroup('InCA');
hToolGroup.open();  % this may be postponed further down for improved performance
hToolGroup.disableDataBrowser();
hToolGroup.hideViewTab
% Store toolgroup reference handle so that app will stay in memory
jToolGroup = hToolGroup.Peer;
internal.setJavaCustomData(jToolGroup, hToolGroup);
hTabGroup = TabGroup();
hToolGroup.addTabGroup(hTabGroup);
hTab = Tab('File');
hTabGroup.add(hTab);  % add to tab as the last section
hTab2 = Tab('Detection');
hTabGroup.add(hTab2);
hTab3 = Tab('Analysis');
hTabGroup.add(hTab3);
hTab4 = Tab('IMR');
hTabGroup.add(hTab4);
