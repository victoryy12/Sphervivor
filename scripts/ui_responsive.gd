extends RefCounted
class_name UiResponsive

## Reference short side (typical 720p height) for ratio = 1.0.
const REF_SHORT := 720.0


static func short_side(viewport: Viewport) -> float:
	var s: Vector2 = viewport.get_visible_rect().size
	return maxf(minf(s.x, s.y), 1.0)


## Scale factor clamped so UI stays usable on tiny phones and 4K displays.
static func ratio(viewport: Viewport, ref: float = REF_SHORT) -> float:
	return clampf(short_side(viewport) / maxf(ref, 1.0), 0.38, 3.0)


static func scale_px(viewport: Viewport, design_px: float, ref: float = REF_SHORT) -> float:
	return maxf(design_px * ratio(viewport, ref), 1.0)


static func scale_px_clamped(viewport: Viewport, design_px: float, mn: float, mx: float, ref: float = REF_SHORT) -> float:
	return clampf(scale_px(viewport, design_px, ref), mn, mx)


static func scale_i_clamped(viewport: Viewport, design_px: float, mn: int, mx: int, ref: float = REF_SHORT) -> int:
	return clampi(int(round(scale_px(viewport, design_px, ref))), mn, mx)
