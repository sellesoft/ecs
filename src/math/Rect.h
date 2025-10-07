/*
 *  A rectangle represented by a start and end point.
 */
#ifndef _ecs_rect_h
#define _ecs_rect_h

#include "math/vec.h"
#include "iro/io/Stream.h"

/* ============================================================================
 */
struct Rect
{
  f32 x, y, w, h;

  static Rect zero()
  {
    return {0,0,0,0};
  }

  static Rect from(f32 x, f32 y, f32 w, f32 h)
  {
    return { x, y, w, h };
  }

  static Rect from(vec2f pos, vec2f size)
  {
    return { pos.x, pos.y, size.x, size.y };
  }

  void set(vec2f pos, vec2f size) { setPos(pos); setSize(size); }
  void setPos(vec2f pos) { x = pos.x; y = pos.y; }
  void setPos(f32 x, f32 y) { this->x = x; this->y = y; }
  Rect& setSize(vec2f size) { w = size.x; h = size.y; return *this; }
  Rect& setSize(f32 x, f32 y) { w = x; h = y; return *this; }
  Rect& setWidth(f32 w) { this->w = w; return *this; }
  Rect& setHeight(f32 h) { this->h = h; return *this; }
  Rect& setSqSize(f32 x) { w = x; h = x; return *this; }

  Rect& mulWidth(f32 v) { w *= v; return *this; }
  Rect& mulHeight(f32 v) { h *= v; return *this; }
  Rect& mulSize(f32 v) { mulWidth(v); mulHeight(v); return *this; }
  Rect& mulSize(f32 x, f32 y) { mulWidth(x); mulHeight(y); return *this; }

  Rect& addPos(vec2f pos) { x += pos.x; y += pos.y; return *this; }

  vec2f pos() const { return {x,y}; }
  vec2f size() const { return {w,h}; }

  f32 extentX() const { return x + w; }
  f32 extentY() const { return y + h; }
  vec2f extent() const { return {extentX(),extentY()}; }

  vec4f asVec4f() const { return vec4f(x,y,w,h); }

  void floorPos() { x = floor(x); y = floor(y); }

  Rect contractedX(f32 v) const { return {x + v, y, w - 2.f * v, h}; }
  void contractX(f32 v) { *this = contractedX(v); }

  Rect contractedY(f32 v) const { return { x, y + v, w, h - 2.f * v}; }
  void contractY(f32 v) { *this = contractedY(v); }

  Rect contracted(f32 v) const { return contractedX(v).contractedY(v); }
  void contract(f32 v) { *this = contracted(v); }

  Rect contracted(f32 vx, f32 vy) const 
    { return contractedX(vx).contracted(vy); }
  void contract(f32 vx, f32 vy) { *this = contracted(vx, vy); }

  Rect contracted(vec2f padding) const
  {
    return contracted(padding.x, padding.y);
  }

  b8 containsPoint(vec2f p) const
  {
    return p.x >= x && p.y >= y && p.x <= x + w && p.y <= y + h;
  }

  b8 containsRect(const Rect& rhs) const
  {
    return rhs.x >= x && rhs.y >= y && 
           rhs.x + rhs.w <= x + w && rhs.y + rhs.h <= y + h;
  }

  Rect clipTo(const Rect& rhs) const
  {
    Rect result = {};
    result.x = max(rhs.x, x);
    result.y = max(rhs.y, y);
    result.w = min(rhs.x + rhs.w, x + w) - result.x;
    result.h = min(rhs.y + rhs.h, y + h) - result.y;
    return result;
  }

  f32 getCenteredY(f32 height) const
  {
    return floor(0.5f * (h - height));
  }

  void expandToContain(const Rect& rhs)
  {
    x = min(rhs.x, x);
    y = min(rhs.y, y);
    w = max(rhs.x + rhs.w, x + w) - x;
    h = max(rhs.y + rhs.h, y + h) - y;
  }

  Rect& alignRightInside(const Rect& rhs, f32 offset)
  {
    x = rhs.extent().x - w - offset;
    return *this;
  }

  Rect& alignLeftOutside(const Rect& rhs, f32 offset)
  {
    x = rhs.x - w - offset;
    return *this;
  }
  
  Rect& alignBottomOutside(const Rect& rhs, f32 offset)
  {
    y = rhs.extentY() + offset;
    return *this;
  }

  Rect& alignCenteredYInside(const Rect& rhs)
  {
    y = floorf(0.5f * (rhs.h - h));
    return *this;
  }

  Rect& fillRemainingHeight(const Rect& rhs)
  {
    h = rhs.extentY() - y;
    return *this;
  }
};

namespace iro::io
{
static s64 format(WStream* io, const Rect& rect)
{
  return io::formatv(io, '(', rect.pos(), ',', rect.size(), ')');
}
}

#endif
