# Neovim TS/TSX 补全插入 `[Symbol]` 问题

## 问题现象

在 `.ts` / `.tsx` 文件中，使用 TypeScript 7（typescript-go 原生移植）的 `tsc --lsp --stdio`
（客户端名 `tsc`，见 `after/lsp/tsc.lua:75`）触发补全时，
偶尔会出现补全结果被错误过滤或插入异常文本的情况。典型的原始数据形如：

```json
{
  "name": "Symbol",
  "kind": "var",
  "insertText": "[Symbol]",
  "replacementSpan": { "start": { "line": 28, "offset": 10 }, "end": { "line": 28, "offset": 11 } }
}
```

即补全条目 `name = Symbol`，但 `insertText = "[Symbol]"`（方括号访问形式）。

## 根因

### 上游：TypeScript 的设计行为（非 bug）

`insertText` 上的 `[Symbol]` 是 TypeScript 的**有意设计**，不是缺陷：

- [#20730 CompletionEntry.insertText](https://github.com/microsoft/TypeScript/issues/20730)
  （Fixed，TS 2.7）：新增 `CompletionEntry.insertText` 字段，用于 `obj['space prop']`
  这类需要方括号访问的补全，配合 `replacementSpan` 返回。
- tsserver 在 `completionInfo` 请求中硬编码携带 `includeInsertTextCompletions: true`，
  TypeScript 7 原生移植的 `tsc --lsp` 在内部把 tsserver 协议转成 LSP 时，
  将其原样透传成 LSP 的 `insertText` + `textEdit`（不经过 typescript-language-server）。
- [#46838](https://github.com/microsoft/TypeScript/issues/46838) 的日志里就包含上面那段原始 JSON。
- [#1568（typescript-go）](https://github.com/microsoft/typescript-go/issues/1568)（PR
  [#1579](https://github.com/microsoft/typescript-go/pull/1579) 已修复）从 server 侧确认：
  *"When an edit is provided the value of insertText is ignored."* —— 即 LSP 规范里
  `textEdit` 存在时 `insertText` 被忽略。规范正确的客户端（VS Code、nvim-cmp、blink.cmp）
  选中该项会插入 `[Symbol]` 并替换 `replacementSpan` 覆盖的范围。

结论：**TS 侧没有开关可以关闭它**，矛盾只能由客户端处理。

### 客户端：Neovim 内置补全的已知 bug

Neovim 内置补全（`vim.lsp.completion`）在转换条目时，`word` 的取值规则是
（`get_completion_word`，见 `runtime/lua/vim/lsp/completion.lua`）：

- 非 snippet 且带 `textEdit` 时：`word = textEdit.newText`，即 `[Symbol]`；
- 弹窗过滤/匹配用 `word`，插入时按 `textEdit` 计算替换范围。

当 `word`（`[Symbol]`）与当前已输入内容不匹配时，`startcol`/`word_boundary` 就会算错，
导致候选被错误过滤或插入异常。

对应官方 issue（**Open，未修复**）：

- [#30905 LSP completion: wrong startcol if label is not a keyword](https://github.com/neovim/neovim/issues/30905)
  — 正是本问题的根因，`label`/`insertText` 非关键字时 `startcol` 错误。
  提交者自附测试用例，并声明 "I have doubts whether this problem is solvable"。
  里程碑 `needs-owner`，短期内不会修。

相关 issue（非根因）：

- [#13829](https://github.com/neovim/neovim/issues/13829) 旧版转换报错
- [#36355](https://github.com/neovim/neovim/issues/36355) 无 `textEdit` 时菜单不弹
- [#39838](https://github.com/neovim/neovim/issues/39838) / [#38433](https://github.com/neovim/neovim/issues/38433) 补全触发回归

## 为什么不能在 `enable` 回调 / 自定义 handler 里修

`vim.lsp.completion.enable(true, callback)` 的第二个参数回调，以及自定义
`textDocument/completion` handler，都运行在 `_convert_results` **之后**：

- 此时 `item.word` 已按错误的 `insertText`/`textEdit.newText`（`[Symbol]`）计算完成；
- `dup` 去重、startcol 对齐也已完成；
- 后处理只能增删条目，救不回已经算错的 `word` 和 `startcol`。

因此能及时生效的正规途径只有：

1. **换用补全插件**（blink.cmp / nvim-cmp）：它们自行接管 client 的
   `textDocument/completion` handler，拿到**原始** `CompletionList`，优先使用 `textEdit`，
   完全不经过 `_convert_results`。最彻底。
2. **重写转换逻辑**：自定义 handler 中用公开的 `vim.lsp.util.extract_completion_items`
   拿原始数据自行转换 —— 代价高，等于复刻私有实现，不推荐。

## 当前方案（monkey patch）

由于上游不会修、回调和 handler 时机太晚、又不想引入补全插件，
目前的解法是在 `_convert_results` 内拦截，把方括号访问条目从"拖垮边界"
改成"边界不动、选中时删点"，两全。

tsc 的成员补全会把 `obj["space prop"]` 这类条目表示成 `textEdit.range.start`
位于 `.` 上（word_boundary 之前）的方括号访问形式（`insertText`/`newText` 形如
`["foo bar"]`、`[Symbol]`、`[Symbol.iterator]`）。这些条目会把 `server_start_boundary`
拖回 `.`，导致两类问题：

1. 合法标识符候选被前缀 `.xxx` 错误过滤（补全结果凭空消失）；
2. `[Symbol]` 这类表达式键被选中后越界替换掉 `.`，插入异常文本。

原因：`vim.fn.complete()` 只有一个 `start_col`（= `server_start_boundary + 1`），
`word` 的替换区间固定为 `[start_col, 光标)`。方括号条目要插入正确必须让
`start_col` 落在 `.` 上（`o.f` -> `o["foo bar"]`），普通成员要插入正确必须让
`start_col` 落在词边界上（`o.f` -> `o.foo`）——二者冲突，nvim 单边界模型
无法同时满足。

方案：**把边界固定在词边界，方括号条目的点号删除交给 `additionalTextEdits`。**

- 检测成员上下文：存在 `textEdit.start` 在 word_boundary 之前、且 `newText` 以
  `[` 开头的条目（即方括号键条目）。
- 把 `server_start_boundary` 强制回 `word_boundary`（利用 0.12 的逻辑：传参
  非 nil 且与 `curstartbyte` 不同时，重置为 `client_start_boundary`）。于是普通
  成员插入位置正确（`o.` -> `o.Symbol`），前缀也正确（`o.f` 的前缀是 `f` 而非
  `.f`）。
- 给每个方括号条目补一段 `additionalTextEdits`：删除 `[点, word_boundary)`。
  accept 时 `on_complete_done` 先插入 `word`（`["foo bar"]`，插在词边界处），
  再应用这段编辑删掉点号，最终 `o.` -> `o["foo bar"]`。

效果

| 输入 | 候选 | 选中结果 |
|---|---|---|
| `o.` | `a` `Symbol` `foo` `"foo bar"` `"[foo]"` | `o.a` / `o.Symbol` / `o.foo` / `o["foo bar"]` / `o["[foo]"]` |
| `o.f` | `foo` | `o.foo` |
| `o.S` | `Symbol` | `o.Symbol` |

方括号条目只在 `o.`（空前缀）时出现；继续输入字母时 nvim core 会按 `word`
（`["foo bar"]`）过滤掉它们，这是预期的（点号前缀输入本就不该匹配字符串键）。

实现见 `lua/core/lsp/tsc.lua`。

```lua
local M = {}

local function is_bracket_text(text)
  return text ~= nil and text:sub(1, 1) == "["
end

local function text_edit_text(item)
  local te = item.textEdit
  if not te then
    return nil
  end
  if te.range then
    return te.newText
  end
  if te.insert then
    return te.insert.text
  end
  return nil
end

local function text_edit_start(item, lnum)
  local te = item.textEdit
  if not te then
    return nil
  end
  if te.range and te.range.start.line == lnum then
    return te.range.start
  end
  if te.insert and te.insert.start.line == lnum then
    return te.insert.start
  end
  return nil
end

function M.setup()
  local completion = vim.lsp.completion
  local convert_results = completion._convert_results

  completion._convert_results = function(line, lnum, cursor_col, client_id, ...)
    local client = vim.lsp.get_client_by_id(client_id)
    if client and client.name == "tsc" then
      local args = { ... }
      local word_boundary = args[1]
      local result = args[3]
      local encoding = args[4]
      local items = result and result.items
      if items then
        local dot_byte, dot_char = nil, nil
        for _, item in ipairs(items) do
          local start = text_edit_start(item, lnum)
          if start and is_bracket_text(text_edit_text(item)) then
            local sb = vim.str_byteindex(line, encoding, start.character, false)
            if sb < word_boundary and (not dot_byte or sb < dot_byte) then
              dot_byte, dot_char = sb, start.character
            end
          end
        end

        if dot_byte then
          -- 成员上下文：把边界强制回词边界，方括号条目选中时删掉点号。
          args[2] = word_boundary
          local wb_char = vim.str_utfindex(line, encoding, word_boundary)
          for _, item in ipairs(items) do
            if is_bracket_text(text_edit_text(item)) then
              local delete = {
                range = {
                  start = { line = lnum, character = dot_char },
                  ["end"] = { line = lnum, character = wb_char },
                },
                newText = "",
              }
              item.additionalTextEdits = vim.list_extend(
                { delete },
                item.additionalTextEdits or {}
              )
            end
          end
          result = vim.tbl_extend("force", result, { items = items })
          args[3] = result
        end
      end
      return convert_results(line, lnum, cursor_col, client_id, unpack(args, 1, 4))
    end

    return convert_results(line, lnum, cursor_col, client_id, ...)
  end
end

return M
```

### 注意：0.12 版本的参数差异

`_convert_results` 的签名在 Neovim 0.12 已改为：

```lua
_convert_results(line, lnum, cursor_col, client_id,
                 client_start_boundary, server_start_boundary, result, encoding)
```

- `args[1]` 是 `client_start_boundary`，即 handler 里的 `word_boundary`
  （`vim.fn.match(line_to_cursor, '\\k*$')`），也是 patch 过滤的正确基准；
- `args[2]`（`server_start_boundary`）在拦截时刻**恒为 nil**：0.12 的 handler
  总是传 `nil`，由 `_convert_results` 内部 `adjust_start_col` 根据所有条目的
  `textEdit.range.start` 计算最小值。因此**不要**用 `args[2]` 作过滤基准，
  那会拿到 nil 并让 `vim.str_byteindex` 报错。

## 补全插件如何规避（以 nvim-cmp / blink.cmp 为例）

两者都不走 Neovim 内置的 `_convert_results`（各自接管 client 的
`textDocument/completion`，拿到**原始** `CompletionList`），且都不依赖
`textEdit.newText` 做匹配、不以 `word`/`startcol` 计算替换范围。

### nvim-cmp

内部也会算出 `word = "[Symbol]"`，但"匹配 / 展示 / 替换"三者彻底分离：

1. **匹配只用 `filterText`/`label`**（`lua/cmp/entry.lua:92`、`447-449`）

   ```lua
   self.filter_text = item.filterText or str.trim(item.label)  -- "Symbol"
   score, matches = matcher.match(input, filter_text, option)
   ```

   `word`（`entry.lua:192-200`，取 `textEdit.newText`）只作为 `synonyms` 兜底别名
   （`entry.lua:439`），敲 `Sym` 匹配的是 `Symbol`，不会拿 `[Symbol]` 过滤。
   这与 Neovim 内置（拿 word 当过滤基准）是本质区别。

2. **展示 `abbr = label`**（`entry.lua:322`），弹窗显示 `Symbol` 而非 `[Symbol]`。

3. **确认直接应用 `textEdit` 的 range**（`lua/cmp/core.lua:443-459`）

   ```lua
   if behavior == types.cmp.ConfirmBehavior.Replace then
     completion_item.textEdit.range = e.replace_range   -- 来自 item.textEdit (entry.lua:95-97)
   else
     completion_item.textEdit.range = e.insert_range
   end
   ```

   `newText = textEdit.newText`（`core.lua:463`），range 来自 tsserver 的
   `replacementSpan`（只覆盖 `req.` 里的 `.`），替换后即 `req[Symbol]`。
   替换范围完全由 server 的 textEdit 决定，`word`/`startcol` 的换算在此不存在
   （这正是 #30905 病根被绕开的地方）。

4. **针对 insertText/newText 与 label 不一致的兜底**（`entry.lua:451-468`）
   "Support the language server that doesn't respect VSCode's behaviors"——当
   `filterText` 匹配失败、但 `textEdit.newText` 包含已输入前缀时，用
   `prefix .. filter_text` 重试匹配。`[Symbol]` 正属此类。

### blink.cmp

更彻底，**完全不计算 `word`**：

1. **原始数据保留**（`lua/blink/cmp/sources/lsp/completion.lua:30`、`45-92`）：
   `client:request('textDocument/completion', ...)` 直接拿原始 `CompletionList`，
   `process_response` 只挂 `client_id`/`pos` 元数据，`textEdit`/`insertText`/`label` 原样保留。
2. **匹配只用 `label`/`filterText`**（`lua/blink/cmp/fuzzy/rust/fuzzy.rs:97`）：
   Rust fuzzy 打分对象是 `filter_text` 或 `label`，与 `textEdit.newText` 无关。
3. **确认只用 `textEdit`**（`lua/blink/cmp/lib/text_edits.lua:130-165`）：
   有 `textEdit` 就用（range 来自 `replacementSpan`），`insertText` 按 LSP 规范忽略；
   无 `textEdit` 时才用 `insertText`/`label` 猜 range（`guess`，`L209-226`）。

### 两者的"免死金牌"总结

- 不走 `_convert_results`，无 `startcol`/`word_boundary` 换算；
- 匹配不依赖 `textEdit.newText`（分别用 label/filterText 或仅 label）；
- 确认时以 `textEdit` 的 range 为准（规范：`textEdit` 存在时 `insertText` 被忽略）。

## 关键参考链接

- https://github.com/microsoft/TypeScript/issues/20730
- https://github.com/microsoft/TypeScript/issues/46838
- https://github.com/neovim/neovim/issues/30905
- https://github.com/microsoft/TypeScript/issues/21408
- https://github.com/microsoft/typescript-go/issues/1568
- https://github.com/microsoft/typescript-go/pull/1579
- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_completion
  `lua/blink/cmp/fuzzy/rust/fuzzy.rs`、`lua/blink/cmp/lib/text_edits.lua`
