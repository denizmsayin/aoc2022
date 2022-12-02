-- rock 0, paper 1, scissors 2

function get_match_score(a, b)
    if a == b then
        return 3
    elseif (a - 1) % 3 == b then
        return 6
    else
        return 0
    end
end

-- What the hell is going on here... Why is everything so hard!?
function numcvt(letter, base_letter)
    return string.byte(letter, 1) - string.byte(base_letter, 1)
end

total_score = 0
for l in io.lines() do
    me = numcvt(string.sub(l, 3, 3), 'X')
    other = numcvt(string.sub(l, 1, 1), 'A')
    match_score = get_match_score(me, other)
    choice_score = me + 1
    total_score = total_score + match_score + choice_score
end
print(total_score)
