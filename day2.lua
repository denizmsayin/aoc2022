utils = require('lib/utils')

-- rock 0, paper 1, scissors 2

function get_match_score(my_move, opponent_move)
    if my_move == opponent_move then
        return 3
    elseif (my_move - 1) % 3 == opponent_move then
        return 6
    else
        return 0
    end
end

function numcvt(letter, base_letter)
    return letter:byte() - base_letter:byte()
end

function choose_move_get_match_score(letter, opponent_move)
    local offset = numcvt(letter, 'X') - 1 -- -1 to lose, 0 to draw and +1 to win
    local score = 3 * (offset + 1)
    return (opponent_move + offset) % 3, score
end

total_score = 0
for l in io.lines() do
    opponent_move = numcvt(l:sub(1, 1), 'A')
    if utils.is_part_1() then
        my_move = numcvt(l:sub(3, 3), 'X')
        match_score = get_match_score(my_move, opponent_move)
    else
        my_move, match_score = choose_move_get_match_score(l:sub(3, 3), opponent_move)
    end
    choice_score = my_move + 1
    total_score = total_score + match_score + choice_score
end
print(total_score)
