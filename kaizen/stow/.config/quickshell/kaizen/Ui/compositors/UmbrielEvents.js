// The list a `subscribe` event of family carries, or null for another event.
function snapshot(event, family) {
  return event && event.event === family && Array.isArray(event.data)
    ? event.data
    : null;
}
