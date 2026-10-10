// fwupd backend: lists pending updates from the daemon's local metadata, which
// fwupd-refresh.timer downloads. --json skips the stale-metadata prompt and
// exits 0 with an empty Devices array when nothing is pending.

var name = "fwupd";
var busName = "org.freedesktop.fwupd";

function command() {
  return ["fwupdmgr", "get-updates", "--json"];
}

function updateCommand(id) {
  return "fwupdmgr update " + id;
}

// Release descriptions are AppStream markup: <p>, <ul>/<ol> and <li>.
function plainText(markup) {
  return String(markup || "")
    .replace(/<li>/g, "• ")
    .replace(/<\/(p|li)>/g, "\n")
    .replace(/<[^>]*>/g, "")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/\n{2,}/g, "\n")
    .trim();
}

// The vendor's details page when set, else the LVFS device page. Only https
// reaches xdg-open.
function releaseUrl(release) {
  if (/^https:\/\//.test(release.DetailsUrl || "")) return release.DetailsUrl;
  if (release.AppstreamId)
    return "https://fwupd.org/lvfs/devices/" + release.AppstreamId;
  return "";
}

function has(list, value) {
  return (list || []).indexOf(value) >= 0;
}

// Releases come newest first.
function parse(text) {
  var data;
  try {
    data = JSON.parse(text);
  } catch (e) {
    return { updates: [], error: "fwupdmgr: unreadable output" };
  }
  var updates = (data.Devices || [])
    .filter(function (device) {
      return (device.Releases || []).length > 0;
    })
    .map(function (device) {
      var release = device.Releases[0];
      return {
        backend: name,
        id: device.DeviceId || "",
        name: device.Name || "",
        vendor: device.Vendor || "",
        current: device.Version || "",
        version: release.Version || "",
        urgency: release.Urgency || "",
        summary: release.Summary || "",
        notes: plainText(release.Description),
        url: releaseUrl(release),
        issues: release.Issues || [],
        needsAc: has(device.Flags, "require-ac"),
        needsReboot: has(device.Flags, "needs-reboot"),
        command: updateCommand(device.DeviceId || ""),
      };
    });
  return { updates: updates, error: "" };
}
