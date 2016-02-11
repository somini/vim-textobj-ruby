" Integration with https://github.com/kana/vim-textobj-function.
if !exists('b:textobj_function_select')
	let b:textobj_function_select = function('textobj#ruby#function_select')

	if exists('b:undo_ftplugin')
		let b:undo_ftplugin .= '|'
	else
		let b:undo_ftplugin = ''
	endif
	let b:undo_ftplugin .= 'unlet b:textobj_function_select'
endif
