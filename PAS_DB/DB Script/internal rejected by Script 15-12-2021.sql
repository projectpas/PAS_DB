


ALTER TABLE SalesOrderApproval ADD InternalRejectedById bigint;
ALTER TABLE SalesOrderApproval ADD InternalRejectedByName varchar(100); 
ALTER TABLE SalesOrderApproval ADD InternalRejectedDate datetime2(7); 

ALTER TABLE SalesOrderApprovalAudit ADD InternalRejectedById bigint;
ALTER TABLE SalesOrderApprovalAudit ADD InternalRejectedByName varchar(100); 
ALTER TABLE SalesOrderApprovalAudit ADD InternalRejectedDate datetime2(7); 


ALTER TABLE SalesOrderQuoteApproval ADD InternalRejectedById bigint;
ALTER TABLE SalesOrderQuoteApproval ADD InternalRejectedByName varchar(100); 
ALTER TABLE SalesOrderQuoteApproval ADD InternalRejectedDate datetime2(7); 

ALTER TABLE SalesOrderQuoteApprovalAudit ADD InternalRejectedById bigint;
ALTER TABLE SalesOrderQuoteApprovalAudit ADD InternalRejectedByName varchar(100); 
ALTER TABLE SalesOrderQuoteApprovalAudit ADD InternalRejectedDate datetime2(7); 