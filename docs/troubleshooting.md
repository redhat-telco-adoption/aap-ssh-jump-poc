# Troubleshooting Guide

## Common Issues

### Infrastructure Deployment Fails

**Symptoms**: Terraform apply fails
**Solutions**:
- Check AWS credentials: `aws sts get-caller-identity`
- Verify Route53 domain ownership
- Check Terraform logs for specific errors

### AAP Installation Fails

**Symptoms**: Installation script errors
**Solutions**:
- Check system resources: 8GB+ RAM, 80GB+ disk
- Verify network connectivity to execution node
- Check installation logs in `/tmp/ansible-automation-platform-installer/`

### SSH Access Issues

**Symptoms**: Cannot SSH to hosts
**Solutions**:
- Check SSH key permissions: `ls -la working/keys/`
- Test connectivity step by step (bastion → AAP → managed)
- Verify security group rules

### AAP Controller Provisioning Fails

**Symptoms**: Ansible controller modules fail
**Solutions**:
- Test AAP API: `curl -k https://your-aap-url/api/v2/ping/`
- Verify credentials in configuration file
- Check SSH key exists and is readable

## Getting Help

For additional support:
1. Check the main README.md troubleshooting section
2. Collect logs using the troubleshooting script
3. Review AAP and AWS documentation
