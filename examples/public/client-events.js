function customEvent(evt, target, sender, eventType, opts) {
    console.log(`Custom event triggered: ${eventType} on ${target.attr('pode-id')}`);
}