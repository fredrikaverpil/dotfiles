// PipeWire casts come through the portal, as an app's screen share; paused
// ones count. wlr-screencopy casts are local tools such as wf-recorder.
function sharing(casts) {
  return casts.some(function (cast) {
    return cast.kind === "PipeWire";
  });
}
