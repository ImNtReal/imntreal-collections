#!/usr/bin/python

# Copyright (c) 2020 Jameson Pugh

ANSIBLE_METADATA = {
  'metadata_version': '1.1',
  'supported_by': 'community',
  'status': ['preview']
}

DOCUMENTATION = r'''
---
module: mssql_user

short_description: Add users to a SQL Server instance

description:
  - Add users to a SQL Server instance.

version_added: "2.2"

author:
  - Arnav Singh (@arsing)
  - Jameson Pugh (@ImNtReal)

options:
  name:
    description:
      - The name of the user to add
    required: true
  login:
    description:
      - The login of the user to add
    required: true
  login_port:
    description:
      - The TDS port of the instance
    required: false
    default: 1433
  login_name:
    description:
      - The name of the user to log in to the instance
    required: true
  login_password:
    description:
      - The password of the user to log in to the instance
    required: true
  host:
    description:
      - The 'host' part of the MySQL username.
    type: str
    default: localhost
  state:
    description:
      - Whether the user should exist.
      - When C(absent), removes the user.
    type: str
    choices: [ absent, present ]
    default: present

notes:
  - Requires the pymssql package (eventually replaced with either pyodbc or pytds).

requirements:
  - python >= 2.7
  - pymssql
'''

EXAMPLES = r'''
# Create a user named 'foo' for the login named 'bar'
- mssql_user:
    name: foo
    login: bar
    login_name: sa
    login_password: password
    host: sqlserver
'''

RETURN = r'''
name:
  description: The name of the user that was added
  returned: success
  type: string
  sample: foo
'''


from ansible.module_utils.basic import AnsibleModule
import pymssql

def main():
  module = AnsibleModule(
    argument_spec = dict(
      name = dict(required = True),
      login = dict(required = True),
      login_port = dict(required = False, default = 1433),
      login_name = dict(required = True),
      login_password = dict(required = True, no_log = True),
      host=dict(type='str', default='localhost')
    )
  )

  name = module.params['name']
  login = module.params['login']
  login_port = module.params['login_port']
  login_name = module.params['login_name']
  login_password = module.params['login_password']
  host = module.params['host']

  cursor = None
  try:
    conn = pymssql.connect(host, login_name, login_password)
    cursor = conn.cursor()

  except Exception as e:
    module.fail_json(msg="unable to connect to database, check login_user and login_password are correct or %s has the credentials. "
      "Exception message: %s" % (config_file, to_native(e)))

  cursor.execute("SELECT COUNT(*) FROM sys.server_principals WHERE name = %s", (name))
  user_exists = cursor.fetchone()

  if not user_exists[0]:
    cursor.execute('CREATE USER %s FOR LOGIN %s', (name, login))
    cursor.close()
    conn.close()
    module.exit_json(changed = True, name = name)

  module.exit_json(changed = False)

if __name__ == '__main__':
  main()
