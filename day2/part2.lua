function numcvt(letter, base_letter)
    return string.byte(letter, 1) - string.byte(base_letter, 1)
end

-- X lose, Y draw, Z win
function choose_move_get_match_score(letter, opponent_move)
    local offset = numcvt(letter, 'X') - 1 -- -1 to lose, 0 to draw and +1 to win
    local score = 3 * (offset + 1)
    return (opponent_move + offset) % 3, score
end

total_score = 0
repeat 
    l = io.read()
    if l then
        letter = string.sub(l, 3, 3)
        other = numcvt(string.sub(l, 1, 1), 'A')
        me, match_score = choose_move_get_match_score(letter, other)
        choice_score = me + 1
        total_score = total_score + match_score + choice_score
    end
until l == nil
print(total_score)
