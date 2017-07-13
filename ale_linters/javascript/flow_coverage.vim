" Author: Zach Perrault -- @zperrault
" Description: FlowType checking for JavaScript files

call ale#Set('javascript_flow_executable', 'flow')
call ale#Set('javascript_flow_use_global', 0)

function! ale_linters#javascript#flow_coverage#GetExecutable(buffer) abort
    return ale#node#FindExecutable(a:buffer, 'javascript_flow', [
    \   'node_modules/.bin/flow',
    \])
endfunction

function! ale_linters#javascript#flow_coverage#VersionCheck(buffer) abort
    return ale#Escape(ale_linters#javascript#flow_coverage#GetExecutable(a:buffer))
    \   . ' --version'
endfunction

function! ale_linters#javascript#flow_coverage#GetCommand(buffer, version_lines) abort
    let l:flow_config = ale#path#FindNearestFile(a:buffer, '.flowconfig')

    if empty(l:flow_config)
        " Don't run Flow if we can't find a .flowconfig file.
        return ''
    endif

    return ale#Escape(ale_linters#javascript#flow_coverage#GetExecutable(a:buffer))
    \   . ' coverage --json --from ale %s'
endfunction

function! ale_linters#javascript#flow_coverage#Handle(buffer, lines) abort
    let l:str = join(a:lines, '')

    if l:str ==# ''
        return []
    endif

    let l:flow_output = json_decode(l:str)
    let l:output = []

    for l:uncovered_loc in get(get(l:flow_output, 'expressions'), 'uncovered_locs', [])
        call add(l:output, {
        \   'lnum': l:uncovered_loc.start.line,
        \   'col': l:uncovered_loc.start.column,
        \   'end_lnum': l:uncovered_loc.end.line,
        \   'end_col': l:uncovered_loc.end.column,
        \   'text': 'Flow: Uncovered',
        \   'type': 'W',
        \})
    endfor

    return l:output
endfunction

call ale#linter#Define('javascript', {
\   'name': 'flow-coverage',
\   'executable_callback': 'ale_linters#javascript#flow_coverage#GetExecutable',
\   'command_chain': [
\       {'callback': 'ale_linters#javascript#flow_coverage#VersionCheck'},
\       {'callback': 'ale_linters#javascript#flow_coverage#GetCommand'},
\   ],
\   'callback': 'ale_linters#javascript#flow_coverage#Handle',
\   'add_newline': 1,
\})
