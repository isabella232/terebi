require 'busted'

local Terebi = require 'terebi'

local noop = function()
  return spy.new(function() end)
end

describe('Terebi:', function()
  before_each(function()
    _G.love = {
      graphics = {},
      window = {},
    }
    _G.love.graphics.newCanvas = spy.new(function(w, h)
      return {w, h}
    end)
    _G.love.window.getDesktopDimensions = spy.new(function()
      return 1600, 1200
    end)
    _G.love.window.getFullscreen = spy.new(function()
      return false
    end)
    _G.love.window.getMode = spy.new(function()
      return 640, 480, 'expected_mode'
    end)
  end)

  describe('When calling initializeLoveDefaults:', function()
    before_each(function()
      _G.love.graphics.setDefaultFilter = noop()
      _G.love.graphics.setLineStyle = noop()
    end)

    it('It should call correct love2d methods.', function()
      Terebi.initializeLoveDefaults()

      assert.spy(love.graphics.setDefaultFilter).was.called_with('nearest', 'nearest')
      assert.spy(love.graphics.setLineStyle).was.called_with('rough')
    end)
  end)

  describe('When creating a new Screen:', function()
    it('It should have correct default attributes', function()
      local screen = Terebi.newScreen(320, 240, 2)

      assert.spy(love.graphics.newCanvas).was.called_with(320, 240)

      assert.are.same(320, screen._width)
      assert.are.same(240, screen._height)
      assert.are.same(2, screen._scale)
      assert.are.same(2, screen._savedScale)
    end)
  end)

  describe('When calling Screen methods:', function()
    local screen

    before_each(function()
      screen = Terebi.newScreen(320, 240, 2)
    end)

    it('getScale should return scale', function()
      assert.are.same(2, screen:getScale())
    end)

    describe('When changing Screen scale:', function()
      before_each(function()
        _G.love.window.getMode = spy.new(function()
          return 640, 480, {'flags'}
        end)
        _G.love.window.setMode = noop()
      end)

      it('setScale should set the scale', function()
        screen:setScale(1)

        assert.are.same(1, screen._scale)
        assert.spy(love.window.setMode).was.called_with(320, 240, {'flags'})
      end)

      it('setScale should do nothing when passed an invalid number', function()
        screen:setScale(0)
        screen:setScale(-1)

        assert.spy(love.window.setMode).was_not.called()
      end)

      it('increaseScale should set the scale', function()
        screen:increaseScale()

        assert.are.same(3, screen._scale)
        assert.spy(love.window.setMode).was.called_with(960, 720, {'flags'})
      end)

      it('decreaseScale should set the scale', function()
        screen:decreaseScale()

        assert.are.same(1, screen._scale)
        assert.spy(love.window.setMode).was.called_with(320, 240, {'flags'})
      end)

      it('setMaxScale should set the scale', function()
        screen:setMaxScale()

        assert.are.same(5, screen._scale)
        assert.spy(love.window.setMode).was.called_with(1600, 1200, {'flags'})
      end)

      it('toggleFullscreen should toggle fullscreen and maximize scale', function()
        _G.love.window.setFullscreen = noop()

        screen:toggleFullscreen()

        assert.are.same(5, screen._scale)
        assert.spy(love.window.setMode).was.called_with(1600, 1200, {'flags'})
        assert.spy(love.window.setFullscreen).was.called_with(true)
      end)
    end)

    it('draw should draw to canvas', function()
      local originalCanvas = {id = 'originalCanvas'}
      local terebiCanvas = screen._canvas

      _G.love.graphics.getCanvas = spy.new(function()
        return originalCanvas
      end)
      _G.love.graphics.setCanvas = noop()
      _G.love.graphics.clear = noop()
      _G.love.graphics.draw = noop()

      local drawFunc = noop()
      screen:draw(drawFunc, 'arg1', 'arg2')

      assert.spy(love.graphics.setCanvas).was.called(2)
      assert.spy(love.graphics.setCanvas).was.called_with(terebiCanvas)
      assert.spy(love.graphics.clear).was.called()
      assert.spy(drawFunc).was.called_with('arg1', 'arg2')
      assert.spy(love.graphics.setCanvas).was.called_with(originalCanvas)
      assert.spy(love.graphics.draw).was.called_with(terebiCanvas, 0, 0, 0, 2, 2)
    end)
  end)
end)
