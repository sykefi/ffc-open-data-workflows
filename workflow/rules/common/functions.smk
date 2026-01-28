from pandas import read_table


def regex_choice_list(choices):
    return f"(?:{'|'.join([str(x) for x in set(choices)])})"
