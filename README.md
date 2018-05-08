# metabase-jar-automation

# To Run locally (standalone version)
Pull the files into the directory containing the metabase.jar file

Edit the config file to suit your configuration.

chmod +x setup.sh

Run ./setup.sh


# To run 2-app 2-db isntances on aws

edit ansible.cfg to put your private key dir

edit inventory/hosts to put your python dir

edit inventory/groupvars/all to edit your aws config

Finally run ansible-playbook -i inventory/hosts playbooks/site.yml
