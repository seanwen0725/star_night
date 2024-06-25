local extension = Package:new("kuangxiang")
extension.extensionName = "star_night"

Fk:loadTranslationTable{
  ["kuangxiang"] = "狂想终焉",
  ["ks"] = "狂想",
}

local U = require "packages/utility/utility"

local heiwangzi = General(extension, "ks__heiwangzi", "hun", 1, 4)
Fk:loadTranslationTable{
  ["ks__heiwangzi"] = "黑王子",
  ["#ks__heiwangzi"] = "魇",
}

local chi = General(extension, "ks__chi", "hun", 3)
Fk:loadTranslationTable{
  ["ks__chi"] = "赤",
  ["#ks__chi"] = "指引者",
}

local wan = General(extension, "ks__wan", "hun", 3)
Fk:loadTranslationTable{
  ["ks__wan"] = "万",
  ["#ks__wan"] = "捣蛋鬼",
}

local hao = General(extension, "ks__hao", "hun", 4)
Fk:loadTranslationTable{
  ["ks__hao"] = "豪",
  ["#ks__hao"] = "理性者",
}





return extension
