#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Jameson Pugh <imntreal@gmail.com>

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: mssql_facts
version_added: '2.8'
short_description: Create a facts collection for MS SQL Server
description:
- This module shows information from Microsoft SQL Server, such as installed instances and configuration.
notes:
- Microsoft SQL Server must be installed beforehand.
seealso:
- module: mssql_db
author:
- Jameson Pugh (@imntreal)
'''

EXAMPLES = r'''
- name: Gather facts from MS SQL
  mssql_facts:
- name: Displays the Instances
  debug:
    var: ansible_mssql.instances
'''

RETURN = r'''
ansible_facts:
  description: Detailed information about the MS SQL Server installation
  returned: always
  type: complex
  contains:
    ansible_mssql:
      description: Detailed information about the MS SQL Server installation
      returned: always
      type: complex
      contains:
        instances:
          description: Detailed information about MSSQL instances
          returned: always
          type: dict
          sample:
            name: DEFAULT
            version: 14.0.1000
'''
