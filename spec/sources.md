## Sources

Checked September 2026. Prices and service status change; re-check before quoting them to a customer.

**P05 — landing zone**
- AWS service control policies — https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- AWS resource control policies — https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html
- CloudTrail Lake availability change (closed to new customers 2026-05-31) — https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-lake-service-availability-change.html
- IAM Identity Center multi-Region support (2026-02-03) — https://aws.amazon.com/about-aws/whats-new/2026/02/aws-iam-identity-center-multi-region-aws-account-access-and-application-deployment
- Security Hub document history (Security Hub CSPM and the new Security Hub) — https://docs.aws.amazon.com/securityhub/latest/userguide/doc-history.html
- OpenTofu, what's new — https://opentofu.org/docs/intro/whats-new/
- IBM completes HashiCorp acquisition (2025-02-27) — https://newsroom.ibm.com/2025-02-27-ibm-completes-acquisition-of-hashicorp,-creates-comprehensive,-end-to-end-hybrid-cloud-platform
- GitHub Actions OpenID Connect — https://docs.github.com/en/actions/concepts/security/openid-connect
- Trivy security advisories (GHSA-69fq-xp46-6x23) — https://github.com/aquasecurity/trivy/security/advisories
- PCI SSC on the PCI DSS v4.x future-dated requirements — https://blog.pcisecuritystandards.org/now-is-the-time-for-organizations-to-adopt-the-future-dated-requirements-of-pci-dss-v4-x
- NYDFS Part 500 final requirements, effective 2025-11-01 (Hogan Lovells) — https://www.hlc.com/en/publications/nydfs-final-set-of-cybersecurity-requirements-under-amended-part-500-take-effect-november-1-2025
- EIOPA, Digital Operational Resilience Act — https://www.eiopa.europa.eu/digital-operational-resilience-act-dora_en
- Azure CAF enterprise-scale module (archive notice) — https://github.com/Azure/terraform-azurerm-caf-enterprise-scale
- Azure default outbound access — https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
- Microsoft Entra ID, the new name for Azure AD — https://learn.microsoft.com/en-us/entra/fundamentals/new-name

**P06 — multi-cloud active/passive**
- Route 53 record choice with health checking — https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-how-route-53-chooses-records.html
- AWS Interconnect - multicloud — https://aws.amazon.com/interconnect/multicloud/
- Google Cross-Cloud Interconnect — https://docs.cloud.google.com/network-connectivity/docs/interconnect/concepts/cci-overview
- European Commission, Data Act explained — https://digital-strategy.ec.europa.eu/en/factpages/data-act-explained
- Kubernetes v1.37 HPA scale to zero (beta) — https://kubernetes.io/blog/2026/09/02/kubernetes-v1-37-hpa-scale-to-zero-beta/

**P07 — BYOC deployer**
- Pulumi releases — https://github.com/pulumi/pulumi/releases
- Pulumi Azure Native OIDC configuration — https://www.pulumi.com/registry/packages/azure-native/installation-configuration/
- AWS IAM, the confused deputy problem — https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html
- Azure Lighthouse tenants, users and roles — https://learn.microsoft.com/en-us/azure/lighthouse/concepts/tenants-users-roles
- Announcing TypeScript 7.0 — https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/

**P08 — multi-Region HA**
- AWS summary of the DynamoDB service disruption in us-east-1 (October 2025) — https://aws.amazon.com/message/101925/
- DynamoDB global tables: how they work (MREC, MRSC, witness, FIS, settings synchronization) — https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/multi-region-strong-consistency-gt.html
- DynamoDB `UpdateTable` API — https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateTable.html
- Aurora Global Database switchover and failover — https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html
- Introducing ARC Region switch (AWS News Blog) — https://aws.amazon.com/blogs/aws/introducing-amazon-application-recovery-controller-region-switch-a-multi-region-application-recovery-service/
- ARC Region switch plans — https://docs.aws.amazon.com/r53recovery/latest/dg/region-switch-plans.html
- Region switch Route 53 health check block (STOP pattern) — https://docs.aws.amazon.com/r53recovery/latest/dg/route53-health-check-block.html
- Region switch `CreatePlan` API — https://docs.aws.amazon.com/arc-region-switch/latest/api/API_CreatePlan.html
- Region switch pricing — https://docs.aws.amazon.com/r53recovery/latest/dg/pricing-rs.html
- Routing control pricing — https://docs.aws.amazon.com/r53recovery/latest/dg/introduction-pricing-routing-control.html
- Route 53 accelerated recovery for public DNS records — https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-route-53-accelerated-recovery-managing-public-dns-records
- Route 53 `HealthCheckConfig` API (SNI, TLS versions, checker Regions) — https://docs.aws.amazon.com/Route53/latest/APIReference/API_HealthCheckConfig.html
- AWS FIS actions reference — https://docs.aws.amazon.com/fis/latest/userguide/fis-actions-reference.html
- AWS FIS Cross-Region: Connectivity scenario — https://docs.aws.amazon.com/fis/latest/userguide/cross-region-scenario.html
- Reducing the Scope of Impact with Cell-Based Architecture (AWS whitepaper) — https://docs.aws.amazon.com/wellarchitected/latest/reducing-scope-of-impact-with-cell-based-architecture/reducing-scope-of-impact-with-cell-based-architecture.html
- ESMA, designated critical ICT third-party providers (2025-11-18) — https://www.esma.europa.eu/sites/default/files/2025-11/List_of_designated_CTPPs.pdf

## Related / Next

- **Previous:** [P01-P04](01-foundations-microservices-and-delivery.md). **Next:** [P09-P12: pipelines, CDC migration, modernization, IoT](03-data-pipelines-and-migration.md).
- **Curriculum:** [C08 Cloud platforms](../02-curriculum/C08-cloud-platforms-aws-azure-gcp.md) · [C11 Infrastructure as Code](../02-curriculum/C11-infrastructure-as-code.md) · [C15 Production readiness](../02-curriculum/C15-production-readiness-and-incident-response.md) · [C16 Field deployment](../02-curriculum/C16-customer-facing-and-field-deployment.md).
- **Drills:** [deployment drills and incident simulations](../04-drills/03-deployment-and-incident-drills.md) (D-DEP, D-INC) · [architecture sketching](../04-drills/04-architecture-and-api-design-drills.md) (D-ARC).
- **Interview:** [T031-T060 cloud and IaC questions](../07-interview/03-technical-questions-cloud-k8s-devops-iac.md) · [SD11 DNS failover](../07-interview/06-systems-design-core-infrastructure.md#sd11--design-global-traffic-management-and-dns-failover-for-a-multi-region-service) · [SD43 99.99% API](../07-interview/09-systems-design-scale-and-reliability.md#sd43--design-a-customer-critical-api-that-must-deliver-9999-availability) · [SD44 cells](../07-interview/09-systems-design-scale-and-reliability.md#sd44--re-architect-our-platform-into-cells-so-one-bad-deploy-or-tenant-cannot-take-everyone-down) · [SC35 us-east-1 outage role-play](../07-interview/12-customer-scenario-questions-part2.md#sc35--aws-us-east-1-outage-during-meridian-freight-operations).
- **Related projects:** [P21-P24 security and reliability](06-security-and-reliability.md) (P24's game day builds on P08's drills) · [P27 tenant isolation](07-industry-capstones.md#p27--multi-tenant-saas-platform-with-tenant-isolation).
- **Writing up the evidence:** [case-study templates](../06-writing/03-case-study-templates.md) · [architecture writing prompts](../06-writing/04-architecture-writing-prompts-and-deployment-docs.md).
- **Existing repo:** [M06 Cloud foundations](../../01-curriculum/M06-cloud-foundations.md) · [M07 CI/CD and IaC](../../01-curriculum/M07-cicd-and-iac.md) · [M17 Incident response](../../01-curriculum/M17-incident-response-and-escalation.md) · [distributed-systems primitives](../../05-theory/05-distributed-systems-primitives.md) · [labs series C](../../04-labs/series-c-cloud-and-devops.md) · [production-readiness checklist](../../08-templates/production-readiness-checklist.md).
- **Plans:** [90-day plan](../08-plans/03-90-day-plan.md) · [6-month plan](../08-plans/04-6-month-mastery-plan.md).
