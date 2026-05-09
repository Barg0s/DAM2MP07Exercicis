const tools = [
  {
    "type": "function",
    "function": {
      "name": "draw_circle",
      "description":
          "Draws a circle. You can specify position, radius, stroke color, thickness, and fill (solid or gradient).",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"},
          "color": {"type": "string", "description": "Color del contorn (hex), ex: #000000"},
          "thickness": {"type": "number", "description": "Gruix de la línia"},
          "fill": {"type": "boolean", "description": "Cert si el cercle té color d'emplenat"},
          "fillColor": {"type": "string", "description": "Color d'emplenat sòlid (hex)"},
          "gradientType": {"type": "string", "description": "Tipus de gradient: 'none', 'linear', o 'radial'"},
          "gradientColor1": {"type": "string", "description": "Primer color del gradient (hex)"},
          "gradientColor2": {"type": "string", "description": "Segon color del gradient (hex)"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_line",
      "description":
          "Draws a line between two points. Specify coordinates, color, and thickness.",
      "parameters": {
        "type": "object",
        "properties": {
          "startX": {"type": "number"},
          "startY": {"type": "number"},
          "endX": {"type": "number"},
          "endY": {"type": "number"},
          "color": {"type": "string"},
          "thickness": {"type": "number"}
        }
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_rectangle",
      "description":
          "Draws a rectangle or square. For squares, ensure width and height are equal by calculating coordinates correctly.",
      "parameters": {
        "type": "object",
        "properties": {
          "topLeftX": {"type": "number"},
          "topLeftY": {"type": "number"},
          "bottomRightX": {"type": "number"},
          "bottomRightY": {"type": "number"},
          "color": {"type": "string"},
          "thickness": {"type": "number"},
          "fill": {"type": "boolean"},
          "fillColor": {"type": "string"},
          "gradientType": {"type": "string", "description": "'none', 'linear', o 'radial'"},
          "gradientColor1": {"type": "string"},
          "gradientColor2": {"type": "string"}
        },
        "required": ["topLeftX", "topLeftY", "bottomRightX", "bottomRightY"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "delete_shape",
      "description": "Deletes an existing shape or text using its ID.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string", "description": "The ID of the element to delete"}
        },
        "required": ["id"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "modify_shape",
      "description": "Modifies properties of an existing shape. Send ONLY the properties to change. Use it for position, size, or color updates.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "color": {"type": "string", "description": "Nou color en hex"},
          "fillColor": {"type": "string", "description": "Nou color d'emplenat en hex"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radius": {"type": "number"}
        },
        "required": ["id"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "draw_text",
      "description":
          "Writes text on the canvas. Specify content, position, size, color, font family, and style.",
      "parameters": {
        "type": "object",
        "properties": {
          "text": {"type": "string", "description": "El text que s'ha d'escriure"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "fontSize": {"type": "number", "description": "Mida de la font, per defecte 14.0"},
          "color": {"type": "string"},
          "fontFamily": {"type": "string", "description": "Tipografia, ex: 'sans-serif', 'serif', o 'monospace'"},
          "isBold": {"type": "boolean", "description": "Cert per posar el text en negreta"},
          "isItalic": {"type": "boolean", "description": "Cert per posar el text en cursiva"}
        },
        "required": ["text", "x", "y"]
      }
    }
  }
];