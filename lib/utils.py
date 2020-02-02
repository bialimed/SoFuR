import os
import re
import shutil
from time import strftime, gmtime


def getParamFromConf(config, param_name, rule_name, missing_val=None):
    param_value = missing_val
    if "analysis" in config and rule_name in config["analysis"] and param_name in config["analysis"][rule_name] and config["analysis"][rule_name][param_name] != "":  # The param is set for the specific rule
        param_value = config["analysis"][rule_name][param_name]
    elif "analysis" in config and param_name in config["analysis"] and config["analysis"][param_name] != "":  # The param is set for all the rules in the workflow
        param_value = config["analysis"][soft_name]
    elif param_name.upper() in os.environ:  # The param is given by environment
        param_value = os.environ[param_name.upper()]
    return param_value


def getCallableSoft(config, soft_name, rule_name):
    soft_path = getSoft(config, soft_name, rule_name)
    if not os.path.exists(soft_path) and shutil.which(soft_path) is None:
        raise Exception("The software {} cannot be found.".format(soft_path))
    return soft_path


def getSoft(config, soft_name, rule_name):
    soft_path = soft_name
    if "analysis" in config and rule_name in config["analysis"] and soft_name in config["analysis"][rule_name] and config["analysis"][rule_name][soft_name] != "":  # The path is set for the specific rule
        soft_path = config["analysis"][rule_name][soft_name]
    elif "analysis" in config and soft_name in config["analysis"] and config["analysis"][soft_name] != "":  # The path is set for all the rules in the workflow
        soft_path = config["analysis"][soft_name]
    else:  # The path is given by environment
        soft_path = soft_name
        if shutil.which(soft_path) is None:  # The path is not in $PATH
            if soft_name.upper() in os.environ:  # The path is in $soft_name
                soft_path = os.environ[soft_name.upper()]
    return soft_path


def getDictPath(fasta_path):
    if fasta_path.endswith(".gz"):
        fasta_path = fasta_path[:-3]
    dict_path = fasta_path.rsplit(".", 1)[0] + ".dict"
    if not os.path.exists(dict_path):
        raise Exception('The dict file cannot be found for "{}"'.format(fasta_path))
    return dict_path


def commonSubStr(str_a, str_b):
    """Returns the longer common substring from the left of the two strings.

    :param str_a: The first string to process.
    :type str_a: str
    :param str_b: The second string to process.
    :type str_b: str
    :return: The longer common substring.
    :rtype: str
    """
    common = ""
    valid = True
    for char_a, char_b in zip(str_a, str_b):
        if char_a != char_b:
            valid = False
        if valid:
            common += char_a
    return common


def commonSubPathes(pathes_a, pathes_b, use_basename=False):
    """Returns the longer common substring from the left of the two strings.

    :param pathes_a: The first string to process.
    :type pathes_a: list
    :param pathes_b: The second string to process.
    :type pathes_b: list
    :param use_basename: With true the substrings are extracted from the
    basenames. Otherwise they are extracted from all the path.
    :type use_basename: bool
    :return: The longer common substring.
    :rtype: list
    """
    out_list = list()
    for path_a, path_b in zip(pathes_a, pathes_b):
        if use_basename:
            path_a = os.path.basename(path_a)
            path_b = os.path.basename(path_b)
        out_list.append(commonSubStr(path_a, path_b))
    return out_list


def getRuleParam(environment_dict, rule_kwargs_name, param_name, default_val=None):
    value = default_val
    if rule_kwargs_name in environment_dict:
        if param_name in environment_dict[rule_kwargs_name]:
            if environment_dict[rule_kwargs_name][param_name] is not None:
                value = environment_dict[rule_kwargs_name][param_name]
    return value


def getLogMessage(wf_name, msg, log_level="INFO"):
    return '{} - {} [{}] {}'.format(
        strftime("%Y-%m-%d %H:%M:%S", gmtime()),
        wf_name,
        log_level,
        msg
    )
