local TextService = game:GetService("TextService")

local TextMeasure = {}

function TextMeasure.Get(text, textSize, font, width)
    local ok, result = pcall(function()
        return TextService:GetTextSize(
            tostring(text or ""),
            textSize or 13,
            font or Enum.Font.Gotham,
            Vector2.new(width or 1000, 10000)
        )
    end)
    return ok and result or Vector2.zero
end

return TextMeasure
