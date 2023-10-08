" By default we will default to our internal
" configuration settings for prettier
function! prettier#resolver#config#resolve(config, hasSelection, start, end) abort
  " Allow params to be passed as json format
  " convert bellow usage of globals to a get function o the params defaulting to global
  " TODO: Use a list, filter() and join() to get a nicer list of args.
  let l:config_and_sel = {
          \ 'config': a:config,
          \ 'hasSelection': a:hasSelection,
          \ 'start': a:start,
          \ 'end': a:end}

  let l:cmd = s:Flag_use_tabs(l:config_and_sel, '--use-tabs', {}) . ' ' .
          \ s:Flag_tab_width(l:config_and_sel, '--tab-width', {}) . ' ' .
          \ s:Flag_print_width(l:config_and_sel, '--print-width', {}) . ' ' .
          \ s:Flag_parser(l:config_and_sel, '--parser', {}) . ' ' .
          \ s:Flag_range_start(l:config_and_sel, '', {}) . ' ' .
          \ s:Flag_range_end(l:config_and_sel, '', {}) . ' ' .
          \ ' --semi=' .
          \ get(a:config, 'semi', g:prettier#config#semi) .
          \ ' --single-quote=' .
          \ get(a:config, 'singleQuote', g:prettier#config#single_quote) .
          \ ' --bracket-spacing=' .
          \ get(a:config, 'bracketSpacing', g:prettier#config#bracket_spacing) .
          \ ' --jsx-bracket-same-line=' .
          \ get(a:config, 'jsxBracketSameLine', g:prettier#config#jsx_bracket_same_line) .
          \ ' --arrow-parens=' .
          \ get(a:config, 'arrowParens', g:prettier#config#arrow_parens) .
          \ ' --trailing-comma=' .
          \ get(a:config, 'trailingComma', g:prettier#config#trailing_comma) .
          \ ' --config-precedence=' .
          \ get(a:config, 'configPrecedence', g:prettier#config#config_precedence) .
          \ ' --prose-wrap=' .
          \ get(a:config, 'proseWrap', g:prettier#config#prose_wrap) .
          \ ' --html-whitespace-sensitivity ' .
          \ get(a:config, 'htmlWhitespaceSensitivity', g:prettier#config#html_whitespace_sensitivity) .
          \ ' ' . s:Flag_stdin_filepath(l:config_and_sel, '--stdin-filepath', {}) .
          \ ' --require-pragma=' .
          \ get(a:config, 'requirePragma', g:prettier#config#require_pragma) .
          \ ' --end-of-line=' .
          \ get(a:config, 'endOfLine', g:prettier#config#end_of_line) .
          \ ' ' . s:Flag_loglevel(l:config_and_sel, '--loglevel', {}) .
          \ ' ' . s:Flag_stdin(l:config_and_sel, '--stdin', {})

  return l:cmd
endfunction

" Returns either '--range-start X' or an empty string.
function! s:Flag_range_start(config_and_sel, ...) abort
  if (!a:config_and_sel.hasSelection)
    return ''
  endif

  let l:rangeStart =
          \ prettier#utils#buffer#getCharRangeStart(a:config_and_sel.start)

  return '--range-start=' . l:rangeStart
endfunction

" Returns either '--range-end Y' or an empty string.
function! s:Flag_range_end(config_and_sel, ...) abort
  if (!a:config_and_sel.hasSelection)
    return ''
  endif

  let l:rangeEnd =
          \ prettier#utils#buffer#getCharRangeEnd(a:config_and_sel.end)

  return '--range-end=' . l:rangeEnd
endfunction

" Returns '--tab-width=NN'
function! s:Flag_tab_width(config_and_sel, ...) abort
  let l:value = get(
          \ a:config_and_sel.config,
          \ 'tabWidth',
          \ g:prettier#config#tab_width)

  if (l:value ==# 'auto')
    let l:value = prettier#utils#shim#shiftwidth()
  endif

  return '--tab-width=' . l:value
endfunction

" Returns either '--use-tabs' or an empty string.
function! s:Flag_use_tabs(config_and_sel, ...) abort
  let l:value = get(
          \ a:config_and_sel.config,
          \ 'useTabs',
          \ g:prettier#config#use_tabs)

  if (l:value ==# 'auto')
    let l:value = &expandtab ? 'false' : 'true'
  endif

  if ( l:value ==# 'true' )
    return ' --use-tabs'
  else
    return ''
  endif
endfunction

" Returns '--print-width=NN' or ''
function! s:Flag_print_width(config_and_sel, ...) abort
  let l:value = get(
          \ a:config_and_sel.config,
          \ 'printWidth',
          \ g:prettier#config#print_width)

  if (l:value ==# 'auto')
    let l:value = &textwidth
  endif

  if (l:value > 0)
    return '--print-width=' . l:value
  else
    return ''
  endif
endfunction

" Returns '--parser=PARSER' or ''
function! s:Flag_parser(config_and_sel, ...) abort
  let l:value = get(
          \ a:config_and_sel.config,
          \ 'parser',
          \ g:prettier#config#parser)

  if (l:value !=# '')
    return '--parser=' . l:value
  else
    return ''
  endif
endfunction

" Returns '--stdin-filepath=' concatenated with the full path of the opened
" file.
function! s:Flag_stdin_filepath(...) abort
  let l:current_file = simplify(expand('%:p'))
  return '--stdin-filepath="' . l:current_file . '"'
endfunction

" Returns '--loglevel error' or '--log-level error'.
function! s:Flag_loglevel(config_and_sel, flag, props) abort
  let l:level = 'error'
  return a:flag . ' ' . l:level
endfunction

" Returns '--stdin'.
function! s:Flag_stdin(...) abort
  return '--stdin '
endfunction

" Returns a flag name concantenated with its value in the JSON config object or
" in the default global Prettier config.
function! s:Concat_value_to_flag(config_and_sel, flag, props) abort
  let l:global_value = get(g:, 'prettier#config#' . a:props.global_name, "")

  let l:value = get(a:config_and_sel.config, a:props.json_name, l:global_value)

  return a:flag . '=' . l:value
endfunction

" Maps a flag name to a part of a command.
function! s:Map_flag_to_cmd_part(config_and_sel, flag, props) abort
  return a:props.mapper(a:config_and_sel, a:flag, a:props)
endfunction
