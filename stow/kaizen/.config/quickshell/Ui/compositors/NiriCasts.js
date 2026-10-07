// casts follows niri's event stream: a full list first, then single changes.
function eventResult(casts, event) {
  if (!event) return casts;
  if (event.CastsChanged) return event.CastsChanged.casts || [];
  if (event.CastStartedOrChanged) {
    var cast = event.CastStartedOrChanged.cast;
    return casts
      .filter(function (other) {
        return other.stream_id !== cast.stream_id;
      })
      .concat([cast]);
  }
  if (event.CastStopped)
    return casts.filter(function (other) {
      return other.stream_id !== event.CastStopped.stream_id;
    });
  return casts;
}

// PipeWire casts come through the portal, as an app's screen share; paused
// ones count. wlr-screencopy casts are local tools such as wf-recorder.
function sharing(casts) {
  return casts.some(function (cast) {
    return cast.kind === "PipeWire";
  });
}
