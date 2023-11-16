function! DebracketLoneGroups(selector) dict
    let exp = a:selector
    return substitute(exp, '(\(\w\+\))', '\1', 'g')
endfunction

function! ProcessExp(selector) dict
    let exp = a:selector


    let [match_exp, start_idx, end_idx] = matchstrpos(exp, '(!?\w\+\([&&\|||]!?\w\+\)*)', 0)
    while match_exp != ''
        let tmp_class_name = self["prv_process_most_nested_exp"](match_exp)
        let exp = strpart(exp, 0, start_idx) . tmp_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '(!?\w\+\([&&\|||]!?\w\+\)*)', end_idx)
    endwhile
    call doc["pub_set_new_tmp_class"](1)
endfunction

function! ProcessMostNestedExp(expression) dict
    let exp = a:expression
    call doc["pub_set_new_tmp_class"](0)

    "*- first handle NOTs -*
    let [match_exp, start_idx, end_idx] = matchstrpos(exp, '!\w\+', 0)
    while match_exp != ''
        let tmp_class_name = self["prv_process_most_nested_exp"](match_exp)
        let exp = strpart(exp, 0, start_idx) . tmp_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '!\w\+', end_idx)
    endwhile

    "*- then handle ANDs -*
    let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+&&\w\+', 0)
    while match_exp != ''
        let tmp_class_name = self["prv_process_most_nested_exp"](match_exp)
        let exp = strpart(exp, 0, start_idx) . tmp_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+[&&\|||]\w\+', end_idx)
    endwhile

    "*- finally handle ORs -*
    let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+||\w\+', 0)
    while match_exp != ''
        let tmp_class_name = self["prv_process_most_nested_exp"](match_exp)
        let exp = strpart(exp, 0, start_idx) . tmp_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+||\w\+', end_idx)
    endwhile


    call doc["pub_set_new_tmp_class"](0)
    call doc["pub_set_new_tmp_class"](1)
endfunction

function! ClassNameCheck(selector) dict
    let exp = a:selector
    let class_names = []
    let class_count = 0
    let [match_name, start_idx, end_idx] = matchstrpos(exp, '\w\+', 0)
    while match_name != ''
        let class_count = class_count + 1
        call doc["class"]["pub_class_name_check"](class_name)
        matchstrpos(exp, '\w\+', end_idx)
    endwhile
    if class_count == 0
        echo "\n"
        throw "No Class Name in Selector"
    endif
endfunction

function! AdjacentGroupCheck(selector) dict
    let exp = a:selector
    let invalid_patterns = [')\w\+', '\w\+(', ')(', '()', '!)', '\w\+!', ')!', '!\{2,\}', '!&', '!|', '&!', '|!']
    for pattern in invalid_patterns
        if exp =~ pattern
            echo '\n'
            throw "Invalid Grouping Pattern"
        endif
    endfor
endfunction

function! UnbalancedBracketsCheck(selector) dict
    let exp = a:selector
    let braces_count = 0
    let [brace_match, start_idx, end_idx] = matchstrpos(exp, "[()]", 0)
    while brace_match != ''
        let [brace_match, start_idx, end_idx] = matchstrpos(exp, "[()]", end_idx)
        if brace_match == ")"
            let braces_count = braces_count - 1
        elseif brace_match == "("
            let braces_count = braces_count + 1
        endif

        if braces_count < 0
            echo "\n"
            throw "Too many ending parenthesis"
        endif
    endwhile

    if braces_count != 0
        echo "\n"
        throw "Unbalanced parenthesis"
    endif
endfunction


let selector_help_obj = {
\   "adjacent_group_check": function("AdjacentGroupCheck"),
\   "unbalanced_brackets_check": function("UnbalancedBracketsCheck"),
\   "selector_class_name_check": function("ClassNameCheck"),
\   "debracket_lone_groups": function("DebracketLoneGroups"),
\   "process_exp": function("ProcessExp"),
\   "prv_process_most_nested_exp": function("ProcessMostNestedExp"),
\}
