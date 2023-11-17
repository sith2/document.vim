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

    call doc["pub_create_tmp_class"](1)
    while match_exp != ''
        let group_class_name = doc["pub_set_new_tmp_class"](1)
        let volatile_lines = self["prv_not"](doc["pub_class_getter"](group_class_name))
        let tmp_volatile_class_name = doc["pub_set_new_tmp_class"](volatile_lines, 1)

        let exp = strpart(exp, 0, start_idx) . tmp_volatile_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '!\w\+', end_idx)
    endwhile

    "*- then handle ANDs -*
    let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+&&\w\+', 0)
    while match_exp != ''
        let left_group_class_name = doc["pub_set_new_tmp_class"](1)
        let right_group_class_name = doc["pub_set_new_tmp_class"](1)
        let volatile_lines = self["prv_and"](
            doc["pub_class_getter"](left_group_class_name), 
            doc["pub_class_getter"](right_group_class_name)
        )
        let tmp_volatile_class_name = doc["pub_set_new_tmp_class"](volatile_lines, 1)

        let exp = strpart(exp, 0, start_idx) . tmp_volatile_class_name . strpart(exp, start_idx, end_idx)

        let exp = strpart(exp, 0, start_idx) . tmp_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+&&\w\+', end_idx)
    endwhile

    "*- finally handle ORs -*
    let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+||\w\+', 0)
    while match_exp != ''
        let left_group_class_name = doc["pub_set_new_tmp_class"](1)
        let right_group_class_name = doc["pub_set_new_tmp_class"](1)
        let volatile_lines = self["prv_or"](
            doc["pub_class_getter"](left_group_class_name), 
            doc["pub_class_getter"](right_group_class_name)
        )
        let tmp_volatile_class_name = doc["pub_set_new_tmp_class"](volatile_lines, 1)

        let exp = strpart(exp, 0, start_idx) . tmp_volatile_class_name . strpart(exp, start_idx, end_idx)

        let exp = strpart(exp, 0, start_idx) . tmp_class_name . strpart(exp, start_idx, end_idx)
        let [match_exp, start_idx, end_idx] = matchstrpos(exp, '\w\+||\w\+', end_idx)
    endwhile
    call doc["pub_clear_tmp_class"](1)


    call doc["pub_set_new_tmp_class"](0)
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

function! Not(lines)
    let all_lines = range(1, line('$'))
    let intersection = filter(copy(a:list1), {_, v -> index(a:list2, v) != -1})
    return filter(copy(union), {_, v -> index(intersection, v) == -1})
endfunction

function! And(lines1, lines2)
    return filter(copy(a:lines1), {_, v -> index(a:lines2, v) != -1})
endfunction

function! Or(lines1, lines2)
    let combined_lines = extend(lines1, lines2)
    let tmp_dict = {}
    for line in a:combined_lines
        let tmp_dict[line] = ""
    endfor
    return sort(map(keys(tmp_dict), 'str2nr(v:val)'), {v1, v2 -> v1 - v2})
endfunction

let selector_help_obj = {
\   "adjacent_group_check": function("AdjacentGroupCheck"),
\   "unbalanced_brackets_check": function("UnbalancedBracketsCheck"),
\   "selector_class_name_check": function("ClassNameCheck"),
\   "debracket_lone_groups": function("DebracketLoneGroups"),
\   "process_exp": function("ProcessExp"),
\   "prv_process_most_nested_exp": function("ProcessMostNestedExp"),
\   "prv_and": function("And"),
\   "prv_or": function("Or"),
\   "prv_not": function("Not"),
\}
