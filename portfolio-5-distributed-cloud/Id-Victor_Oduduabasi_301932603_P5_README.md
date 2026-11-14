# Portfolio 5 Distributed and Cloud Database Exercise

## Current setup

Based on the Portfolio 1 and Portfolio 4 implementation files, the Hospital Management System currently runs inside a single Ubuntu 24.04 GitHub Codespace (`/workspaces/Id-Victor_Oduduabasi_301932603`) without replication or clustering. PostgreSQL hosts nine normalised tables (`patient`, `doctor`, `bed`, `medication`, `admission`, `consultation`, `prescription`, `prescription_item`, and `invoice`) in `hospital_management_portfolio`, enforcing transactional rules such as unique time slots and active bed occupancy. Alongside PostgreSQL, a single standalone MongoDB `8.0.38` instance runs locally on `127.0.0.1:27017` using `/workspaces/mongodb-data` with port forwarding disabled, storing four fictional `hospital_events` documents (`ward_admission` and `consultation_visit`). No replica set configuration, multi-node deployment, or failover testing has been implemented or verified.

## Proposed replication

To eliminate the single point of failure for clinical activity timelines, the standalone MongoDB instance could be replaced by a [three-member replica set](https://www.mongodb.com/docs/manual/replication/) holding identical copies of `hospital_events` across separate hosts or availability zones:

| Member | Starting role | Location |
| :--- | :--- | :--- |
| `mongo-hosp-1` | Primary (voting, data-holding) | Availability Zone A |
| `mongo-hosp-2` | Secondary (voting, data-holding) | Availability Zone B |
| `mongo-hosp-3` | Secondary (voting, data-holding) | Availability Zone C |

When a doctor records a `consultation_visit` event (such as `EVT-2026-004` for Zainab Ibrahim), `mongo-hosp-1` writes the document to its oplog and replicates it asynchronously to `mongo-hosp-2` and `mongo-hosp-3`.

## Failure and consistency

If `mongo-hosp-1` fails, the remaining two members hold a [replica set election](https://www.mongodb.com/docs/v8.0/core/replica-set-elections/) and promote a new primary. Writes to `hospital_events` pause briefly during the election before resuming automatically; however, if two members fail simultaneously and no voting majority remains reachable, the surviving node cannot elect a primary and accepts only reads.

Using [`w: "majority"` write concern](https://www.mongodb.com/docs/v8.0/reference/write-concern/) ensures new `consultation_visit` records persist across at least two nodes before acknowledgement, preventing rollback after failover. Because secondaries replicate asynchronously, reads directed to a secondary may briefly lag behind the primary. Crucially, PostgreSQL remains the authoritative system for strict transactional enforcement—such as preventing double-booked consultation slots, single active bed occupancy, and medication stock deductions—while MongoDB stores replicated event histories.

## Sharding and cloud deployment

Replication copies the full dataset across nodes for availability, whereas [sharding](https://www.mongodb.com/docs/manual/sharding/) partitions records across multiple shards for horizontal write and storage scale. With only four documents (and single-facility scale), this hospital model does not need sharding, which adds routing (`mongos`) and operational complexity.

Deploying MongoDB on a managed cloud service such as MongoDB Atlas would require enabling authentication, TLS encryption in transit, encryption at rest, IP allowlists or VPC peering, and automated [cloud backup and point-in-time restore](https://www.mongodb.com/docs/atlas/backup-restore-cluster/). Managed multi-zone clusters introduce recurring compute and storage costs, and MongoDB replication neither replicates PostgreSQL nor automatically synchronises records between the two databases.

## References

- [MongoDB Manual — Replication](https://www.mongodb.com/docs/manual/replication/)
- [MongoDB 8.0 Manual — Replica Set Elections](https://www.mongodb.com/docs/v8.0/core/replica-set-elections/)
- [MongoDB 8.0 Manual — Write Concern](https://www.mongodb.com/docs/v8.0/reference/write-concern/)
- [MongoDB Manual — Sharding](https://www.mongodb.com/docs/manual/sharding/)
- [MongoDB Atlas — Back Up and Restore Clusters](https://www.mongodb.com/docs/atlas/backup-restore-cluster/)