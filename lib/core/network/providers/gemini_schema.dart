const Map<String, dynamic> qaGenieResponseSchema = {
  "type": "ARRAY",
  "items": {
    "type": "OBJECT",
    "required": [
      "title",
      "priority",
      "type",
      "preconditions",
      "steps",
      "expectedResult"
    ],
    "properties": {
      "title": {
        "type": "STRING",
        "minLength": 12
      },
      "priority": {
        "type": "STRING",
        "enum": ["High", "Medium", "Low"]
      },
      "type": {
        "type": "STRING",
        "enum": [
          "POSITIVE",
          "NEGATIVE",
          "EDGE",
          "SECURITY",
          "SESSION",
          "VALIDATION",
          "USABILITY"
        ]
      },
      "preconditions": {
        "type": "ARRAY",
        "minItems": 1,
        "items": {
          "type": "STRING",
          "minLength": 10
        }
      },
      "steps": {
        "type": "ARRAY",
        "minItems": 2,
        "maxItems": 5,
        "items": {
          "type": "OBJECT",
          "required": [
            "action",
            "data",
            "expected"
          ],
          "properties": {
            "action": {
              "type": "STRING",
              "minLength": 12
            },
            "data": {
              "type": "STRING"
            },
            "expected": {
              "type": "STRING",
              "minLength": 20
            }
          }
        }
      },
      "expectedResult": {
        "type": "STRING",
        "minLength": 25
      }
    }
  }
};
