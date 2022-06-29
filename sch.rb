#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require 'json'

def run_cmd(cmd)
  cmd_output = `#{cmd}`
  abort cmd_output unless $CHILD_STATUS.success?
  cmd_output
end

def auth_token
  cmd_output = run_cmd 'ibmcloud iam oauth-tokens --output json'
  auth_obj = JSON.parse cmd_output
  auth_obj['iam_token']
end

def all_workspaces
  cmd_output = run_cmd 'ibmcloud schematics workspace list --output json'
  JSON.parse(cmd_output)['workspaces']
end

def find_workspaces_by_name(workspaces, workspace_name)
  workspaces.select { |item| item['name'] == workspace_name }
end

def build_template_repo_payload(workspace, tag = nil)
  template_repo = workspace['template_repo']
  {
    'template_repo' => {
      'url' => template_repo['full_url'],
      'release' => tag || template_repo['release'],
      'has_uploadedgitrepotar' => false
    }
  }
end

def dump_variables(workspace)
  puts JSON.generate(workspace['template_data'].first['variablestore'])
end

def dump_valuestore(workspace)
  wks_id = workspace['id']
  tpl_id = workspace['template_data'].first['id']
  cmd_output = run_cmd "ibmcloud schematics state pull --id #{wks_id} --template #{tpl_id}"
  puts cmd_output
end

_ = auth_token
workspaces = all_workspaces
prism = find_workspaces_by_name workspaces, 'dev-deploy-dmserver'
dump_variables prism.first
