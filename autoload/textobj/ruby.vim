let s:save_cpo = &cpo
set cpo&vim

" helpers for syntax
function! s:syntax_from_block(block) "{{{
    for [syntax, names] in items({
                \   'rubyConditional' : ['if', 'unless', 'case'],
                \   'rubyRepeat'      : ['while', 'until', 'for'],
                \   'rubyModule'      : ['module'],
                \   'rubyClass'       : ['class'],
                \   'rubyControl'     : ['do', 'begin'],
                \   'rubyDefine'      : ['def'],
                \ })
        if index(names, a:block) >= 0
            return syntax
        endif
    endfor
    return ''
endfunction

function! s:syntax_highlight(line)
    return synIDattr(synID(a:line, col('.'),1), 'name')
endfunction
"}}}

" implementation to seed head and tail position
function! s:search_head(block, indent) "{{{
    while 1
        let line = search( '\<\%('.a:block.'\)\>', 'bW' )
        if line == 0
            throw 'not found'
        endif

        let syntax = s:syntax_from_block(expand('<cword>'))
        if syntax == ''
            throw 'not found'
        endif

        let current_indent = indent('.')
        if current_indent < a:indent &&
                    \ syntax ==# s:syntax_highlight(line)
            return [syntax, current_indent, getpos('.')]
        endif
    endwhile
endfunction

function! s:search_tail(block, head_indent, syntax)
    while 1
        let line = search( '\<end\>', 'W' )
        if line == 0
            throw 'not found'
        endif

        if indent('.') == a:head_indent &&
                    \ a:syntax ==# s:syntax_highlight(line)
            return getpos('.')
        endif
    endwhile
endfunction
"}}}

" search the block's head and tail positions
function! s:search_block(block) "{{{
    let pos = getpos('.')
    try
        let indent = getline('.') == '' ? cindent('.') : indent('.')
        let [syntax, head_indent, head] = s:search_head(a:block, indent)
        call setpos('.', pos)
        let tail = s:search_tail(a:block, head_indent, syntax)
        return ['V', head, tail]
    catch /^not found$/
        echohl Error | echo 'block is not found.' | echohl None
        call setpos('.', pos)
        return 0
    endtry
endfunction
"}}}

" narrow range by 1 line on both sides
function! s:inside(range) "{{{
    " check if range exists
    if type(a:range) != type([]) || a:range[1][1]+1 > a:range[2][1]-1
        return 0
    endif

    let range = a:range
    let range[1][1] += 1
    let range[2][1] -= 1

    return range
endfunction
"}}}

" create a regex that matches all strings in an array
function! s:array_to_regex(array) "{{{
    return join(a:array, '\|')
endfunction
"}}}

" Block pattern definitions {{{
let s:blocks = {
            \    'function': [
            \        'def',
            \    ],
            \    'class': [
            \        'module',
            \        'class',
            \    ],
            \    'loop': [
            \        'while',
            \        'until',
            \        'for',
            \    ],
            \    'control_other': [
            \        'begin',
            \        'if',
            \        'unless',
            \        'case',
            \    ],
            \    'do': [
            \        'do',
            \    ],
            \}
let s:blocks['control'] = s:blocks['do'] + s:blocks['control_other']
let s:blocks['definition'] = s:blocks['function'] + s:blocks['class']

let s:blocks_all = []
for block in keys(s:blocks)
    call extend(s:blocks_all, s:blocks[block])
endfor
"}}}

" select any block
function! textobj#ruby#any_select_i() " {{{
    return s:inside(textobj#ruby#any_select_a())
endfunction

function! textobj#ruby#any_select_a()
    return s:search_block(s:array_to_regex(s:blocks_all))
endfunction
"}}}

function! s:object_select_a(type)
    return s:search_block(s:array_to_regex(s:blocks[a:type]))
endfunction
function! s:object_select_i(type)
    return s:inside(s:object_select_a(a:type))
endfunction

" select object definition
function! textobj#ruby#object_definition_select_i() "{{{
    return s:object_select_i('definition')
endfunction

function! textobj#ruby#object_definition_select_a()
    return s:object_select_a('definition')
endfunction
"}}}

" select loop
function! textobj#ruby#loop_block_select_i() " {{{
    return s:object_select_i('loop')
endfunction

function! textobj#ruby#loop_block_select_a()
    return s:object_select_a('loop')
endfunction
"}}}

" select control statement
function! textobj#ruby#control_block_select_i() " {{{
    return s:object_select_i('control')
endfunction

function! textobj#ruby#control_block_select_a()
    return s:object_select_a('control')
endfunction
"}}}

" select do block
function! textobj#ruby#do_block_select_i() " {{{
    return s:object_select_i('do')
endfunction

function! textobj#ruby#do_block_select_a()
    return s:object_select_a('do')
endfunction
"}}}

" select function
function! textobj#ruby#function_select(type)
    return textobj#ruby#function_block_select_{a:type}()
endfunction
function! textobj#ruby#function_block_select_i() " {{{
    return s:object_select_i('function')
endfunction

function! textobj#ruby#function_block_select_a()
    return s:object_select_a('function')
endfunction
"}}}

" select classes
function! textobj#ruby#class_block_select_i() " {{{
    return s:object_select_i('class')
endfunction

function! textobj#ruby#class_block_select_a()
    return s:object_select_a('class')
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
