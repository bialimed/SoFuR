# -*- coding: utf-8 -*-
"""Utilities to easy usage of snakemake, rules and their configuration file."""

__author__ = 'Frederic Escudie'
__copyright__ = 'Copyright (C) 2019 IUCT-O'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'
__email__ = 'escudie.frederic@iuct-oncopole.fr'
__status__ = 'prod'

import os
from time import strftime, gmtime


def commonSubPathes(pathes_a, pathes_b, use_basename=False):
    """
    Return the longer common substring from the left of the two strings.

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


def commonSubStr(str_a, str_b):
    """
    Return the longer common substring from the left of the two strings.

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


def getDictPath(fasta_path):
    """
    Return the path to the index (.dict) from the genome fasta path.

    :param fasta_path: Path to the sequence file (format: fasta).
    :type fasta_path: str
    :return: Path to the index (.dict).
    :rtype: str
    """
    if fasta_path.endswith(".gz"):
        fasta_path = fasta_path[:-3]
    dict_path = fasta_path.rsplit(".", 1)[0] + ".dict"
    if not os.path.exists(dict_path):
        raise Exception('The dict file cannot be found for "{}"'.format(fasta_path))
    return dict_path


def getLogMessage(wf_name, msg, log_level="INFO"):
    """
    Return printable log message for the workflow.

    :param wf_name: Name of the workflow.
    :type wf_name: str
    :param msg: Message content.
    :type msg: str
    :param log_level: Logging level.
    :type log_level: str
    :return: Printable log message.
    :rtype: str
    """
    return '{} - {} [{}] {}'.format(
        strftime("%Y-%m-%d %H:%M:%S", gmtime()),
        wf_name,
        log_level,
        msg
    )


def getParamFromConf(config, param_name, rule_name, missing_val=None):
    """
    Return parameter value from the configuration file in subsection analysis or environment.

    :param config: Workflow configuration.
    :type config: configparser
    :param param_name: Parameter name.
    :type param_name: str
    :param rule_name: Section name in subsection analysis.
    :type rule_name: str
    :param missing_val: Value for the parameter if it is missing.
    :type missing_val: str
    :return: Parameter value.
    :rtype: str
    """
    param_value = missing_val
    if "analysis" in config and rule_name in config["analysis"] and param_name in config["analysis"][rule_name] and config["analysis"][rule_name][param_name] != "":  # The param is set for the specific rule
        param_value = config["analysis"][rule_name][param_name]
    elif "analysis" in config and param_name in config["analysis"] and config["analysis"][param_name] != "":  # The param is set for all the rules in the workflow
        param_value = config["analysis"][param_name]
    elif param_name.upper() in os.environ:  # The param is given by environment
        param_value = os.environ[param_name.upper()]
    return param_value


def getSoft(config, soft_name, sub_section=None):
    """
    Return software callable name from configuration file in section software_pathes or from environment.

    :param config: Workflow configuration.
    :type config: OrderedDict
    :param soft_name: Software name.
    :type soft_name: str
    :param sub_section: Section name in subsection software_pathes.
    :type sub_section: str
    :return: Software callable name.
    :rtype: str
    """
    soft_path = soft_name
    # Config file overwrite environment or container
    soft_config = config.get("software_pathes")
    if sub_section is not None:
        subsection_config = soft_config[sub_section]
        if soft_name in subsection_config and subsection_config[soft_name] is not None:
            soft_path = subsection_config[soft_name]
    else:
        if soft_name in soft_config and soft_config[soft_name] is not None:
            soft_path = soft_config[soft_name]
    return soft_path
