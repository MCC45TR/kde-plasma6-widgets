function rotationForPanel(isVertical, location, leftEdge, rightEdge) {
    return rotationForPlacement(automaticPlacement(isVertical, location, leftEdge, rightEdge));
}

// 0 = horizontal, 1 = left edge, 2 = right edge. A vertical panel whose
// location is temporarily unavailable keeps a vertical layout instead of
// collapsing into the horizontal geometry.
function automaticPlacement(isVertical, location, leftEdge, rightEdge) {
    if (!isVertical)
        return 0;
    if (location === rightEdge)
        return 2;
    return 1;
}

function effectivePlacement(useAutomatic, manualPlacement, isVertical, location, leftEdge, rightEdge) {
    if (useAutomatic)
        return automaticPlacement(isVertical, location, leftEdge, rightEdge);
    return Math.max(0, Math.min(2, Number(manualPlacement) || 0));
}

function rotationForPlacement(placement) {
    if (placement === 2)
        return 90;
    if (placement === 1)
        return -90;
    return 0;
}

function longestFittingText(availableWidth, texts, widths) {
    if (!texts || texts.length === 0)
        return "";
    var selected = texts[0];
    var count = Math.min(texts.length, widths ? widths.length : 0);
    for (var i = 0; i < count; i++) {
        if (Number(widths[i]) <= availableWidth)
            selected = texts[i];
    }
    return selected;
}
