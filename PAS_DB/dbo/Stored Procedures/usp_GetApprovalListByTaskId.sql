
--exec [usp_GetApprovalListByTaskId] 5, 62
CREATE Procedure [dbo].[usp_GetApprovalListByTaskId]
@TaskId  bigint,
@ID bigint
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON 
BEGIN TRY

DECLARE @TaskType as varchar(50)
DECLARE @TotalCost as Decimal(18,2)
DECLARE @MSID as bigint
DECLARE @EID as bigint
DECLARE @MasterCompanyID as bigint
DECLARE @TotalCostText as varchar(50)

SELECT @TaskType = Name  
   FROM  dbo.ApprovalTask WITH(NOLOCK)
    WHERE ApprovalTaskId = @TaskId

IF @TaskType = 'PO Approval'
BEGIN
 SET @TotalCostText = 'Total PO Cost'
SELECT @TotalCost = SUM(ExtendedCost)	 
      FROM dbo.PurchaseOrderPart pop  WITH(NOLOCK)
	   WHERE pop.PurchaseOrderId = @ID
	         AND pop.isParent = 1

SELECT @MSID = ManagementStructureId,
	   @EID = po.RequestedBy,	   
		@MasterCompanyID = po.MasterCompanyId
      FROM dbo.PurchaseOrder po  WITH(NOLOCK)
	   WHERE po.PurchaseOrderId = @ID

END

ElSE IF @TaskType = 'RO Approval'
BEGIN
SET @TotalCostText = 'Total RO Cost'
SELECT @TotalCost = SUM(ExtendedCost)
      FROM dbo.RepairOrderPart rop  WITH(NOLOCK)
	   WHERE rop.RepairOrderId = @ID
	         AND rop.IsParent = 1

SELECT @MSID = ManagementStructureId,
	   @EID = ro.RequisitionerId,
	   @MasterCompanyID = ro.MasterCompanyId
      FROM dbo.RepairOrder ro  WITH(NOLOCK)
	   WHERE ro.RepairOrderId = @ID

END
ELSE IF @TaskType = 'Sales Quote Approval'
BEGIN
SET @TotalCostText = 'Total SOQ Cost'

DECLARE @TotalCharges AS DECIMAL(18, 2) = 0;
DECLARE @FlatCharges AS DECIMAL(18, 2) = 0;

SELECT @TotalCharges = ISNULL(SUM(soqc.BillingAmount), 0) FROM DBO.SalesOrderQuoteCharges soqc WITH (NOLOCK) WHERE soqc.SalesOrderQuoteId = @ID 
				AND soqc.IsActive = 1 AND soqc.IsDeleted = 0
DECLARE @BillingMethod INT;

SELECT @BillingMethod = soq.ChargesBilingMethodId, @FlatCharges = soq.TotalCharges FROM dbo.SalesOrderQuote soq WITH(NOLOCK) WHERE soq.SalesOrderQuoteId = @ID

SELECT @TotalCost = sum(soqp.NetSales)
      FROM dbo.SalesOrderQuotePart soqp  WITH(NOLOCK)
	  WHERE soqp.SalesOrderQuoteId = @ID

IF @BillingMethod = 3
BEGIN
	SET @TotalCost = @TotalCost + @FlatCharges;
END
ELSE
BEGIN
	SET @TotalCost = @TotalCost + @TotalCharges
END

SELECT @MSID = ManagementStructureId,
		@EID = soq.EmployeeId,
		@MasterCompanyID = soq.MasterCompanyId
      FROM dbo.SalesOrderQuote soq  WITH(NOLOCK)
	   WHERE soq.SalesOrderQuoteId = @ID

END
ELSE IF @TaskType = 'SO Approval'
BEGIN
SET @TotalCostText = 'Total SO Cost'
--SELECT @TotalCost = sum(sos.NetSales + ISNULL(so.TotalCharges, 0))
--      FROM dbo.SOMarginSummary sos WITH(NOLOCK)
--	  INNER JOIN dbo.SalesOrder so WITH(NOLOCK) on sos.SalesOrderId = so.SalesOrderId
--	  WHERE sos.SalesOrderId = @ID

DECLARE @TotalCharges_SO AS DECIMAL(18, 2) = 0;
DECLARE @FlatCharges_SO AS DECIMAL(18, 2) = 0;

SELECT @TotalCharges = ISNULL(SUM(soc.BillingAmount), 0) FROM DBO.SalesOrderCharges soc WITH (NOLOCK) WHERE soc.SalesOrderId = @ID 
				AND soc.IsActive = 1 AND soc.IsDeleted = 0
DECLARE @BillingMethod_SO INT;

SELECT @BillingMethod_SO = so.ChargesBilingMethodId, @FlatCharges_SO = so.TotalCharges FROM dbo.SalesOrder so WITH(NOLOCK) WHERE so.SalesOrderId = @ID

SELECT @TotalCost = sum(sop.NetSales)
      FROM dbo.SalesOrderPart sop WITH(NOLOCK)
	  WHERE sop.SalesOrderId = @ID

IF @BillingMethod_SO = 3
BEGIN
	SET @TotalCost = @TotalCost + @FlatCharges_SO;
END
ELSE
BEGIN
	SET @TotalCost = @TotalCost + @TotalCharges_SO
END
PRINT @TotalCost
SELECT @MSID = ManagementStructureId,
		@EID = so.EmployeeId,
		@MasterCompanyID = so.MasterCompanyId
      FROM dbo.SalesOrder so  WITH(NOLOCK)
	   WHERE so.SalesOrderId = @ID
END

ELSE IF @TaskType = 'WO Quote Approval'
BEGIN
SET @TotalCostText = 'Total WOQ Cost'
SELECT @TotalCost = sum(woq.MaterialFlatBillingAmount + woq.ChargesFlatBillingAmount + woq.LaborFlatBillingAmount)
      FROM dbo.WorkOrderQuoteDetails woq  WITH(NOLOCK)
	   WHERE woq.WorkOrderQuoteId = @ID

SELECT @MSID = ManagementStructureId,
		@MasterCompanyID = woq.MasterCompanyId
      FROM dbo.WorkOrderQuote woq   WITH(NOLOCK) inner join WorkOrderPartNumber wp  WITH(NOLOCK) on woq.WorkOrderId= wp.WorkOrderId 
	   WHERE woq.WorkOrderQuoteId = @ID

SELECT @EID = woq.EmployeeId
		FROM dbo.WorkOrderQuote woq  WITH(NOLOCK) inner join WorkOrder wp  WITH(NOLOCK) on woq.WorkOrderId= wp.WorkOrderId 
	   WHERE woq.WorkOrderQuoteId = @ID
END

ELSE IF @TaskType = 'WO Approval'
BEGIN
SET @TotalCostText = 'Total WO Cost'
SELECT @TotalCost = sum(woq.MaterialCost + woq.LaborCost + woq.ChargesCost + woq.FreightCost + woq.ExclusionsCost)
      FROM dbo.WorkOrderQuoteDetails woq  WITH(NOLOCK)
	   WHERE woq.WorkOrderQuoteId = @ID

SELECT @MSID = ManagementStructureId,
	  @MasterCompanyID = wo.MasterCompanyId
      FROM dbo.WorkOrder wo  WITH(NOLOCK) inner join WorkOrderPartNumber wp  WITH(NOLOCK) on wo.WorkOrderId= wp.WorkOrderId 
	   WHERE wo.WorkOrderId = @ID

	   SELECT 
		@EID = wo.EmployeeId
      FROM dbo.WorkOrder wo   WITH(NOLOCK)
	   WHERE wo.WorkOrderId = @ID

END
ELSE IF @TaskType = 'Exchange Quote Approval'
BEGIN
SET @TotalCostText = 'Total EQ Cost'
SELECT @TotalCost = eqp.TotalEstRevenue
      FROM dbo.ExchangeQuoteMarginSummary eqp  WITH(NOLOCK)
	   WHERE eqp.ExchangeQuoteId = @ID

SELECT @MSID = ManagementStructureId,
		@EID = eq.EmployeeId,
		 @MasterCompanyID = eq.MasterCompanyId
      FROM dbo.ExchangeQuote eq  WITH(NOLOCK)
	   WHERE eq.ExchangeQuoteId = @ID

END

SET @TotalCost  = ISNULL(@TotalCost,0)

IF OBJECT_ID(N'tempdb..#ARMSID') IS NOT NULL
BEGIN
DROP TABLE #ARMSID 
END

CREATE TABLE #ARMSID 
(
 ID BIGINT NOT NULL IDENTITY, 
 ManagementStructureId BIGINT NULL,
 IsCheck bit default 0
)

INSERT INTO  #ARMSID (ManagementStructureId)
SELECT DISTINCT Ar.ManagementStructureId
	   from dbo.ApprovalRule AR  WITH(NOLOCK)
	     INNER JOIN dbo.Employee E  WITH(NOLOCK) on Ar.ApproverId = E.EmployeeId
		 INNER JOIN dbo.EmployeeManagementStructure EMS   WITH(NOLOCK)
		            on EMS.EmployeeId = E.EmployeeId AND EMS.ManagementStructureId = Ar.ManagementStructureId
		 Where ApprovalTaskId = @TaskId
			   AND AR.IsActive = 1 AND AR.IsDeleted = 0
			   AND AR.managementStructureId > 0
			  AND AR.ApproverId != @EID
			  AND AR.MasterCompanyId = @MasterCompanyID

INSERT INTO  #ARMSID (ManagementStructureId) SELECT  @MSID


Declare  @CNT as int = 0; 
Declare  @SMSID as int = 0; 
Select TOP 1 @CNT = ID,@SMSID = ManagementStructureId  FROM #ARMSID WHERE IsCheck = 0 ORDER BY ID 

WHILE (@SMSID > 0)
BEGIN
INSERT INTO 
#ARMSID 
(ManagementStructureId)
SELECT * from dbo.udfGetMSByMSId(@SMSID)
SET @SMSID = 0;
UPDATE #ARMSID SET IsCheck = 1 WHERE ID  = @CNT
Select TOP 1 @CNT = ID,@SMSID = ManagementStructureId  FROM #ARMSID WHERE IsCheck = 0 ORDER BY ID 
END

SELECT DISTINCT Ar.ApproverId,
       E.FirstName + ' ' + E.LastName as ApproverName,
	   E.EmployeeCode as ApproverCode,
	   E.Email as ApproverEmail,
	   @TotalCost as TotalCost,
	    CASE WHEN AR.AmountId = 1 THEN
	          'Amount is ' +  CONVERT(varchar, CAST(AR.Value AS money), 1)
            WHEN AR.AmountId = 2 THEN
	          'Amount is Not ' +  CONVERT(varchar, CAST(AR.Value AS money), 1)
			WHEN AR.AmountId = 3 THEN
	          'Amount is Equal or Greater then ' +  CONVERT(varchar, CAST(AR.Value AS money), 1)
			WHEN AR.AmountId = 4 THEN
	          'Amount is Equal or Lesser then ' + CONVERT(varchar, CAST(AR.Value AS money), 1)
			WHEN AR.AmountId = 5 THEN
	          'Amount is Is Between '  +  CONVERT(varchar, CAST(AR.LowerValue AS money), 1) + ' And ' + CONVERT(varchar, CAST(AR.UpperValue AS money), 1)
	   END as [Rule],
	   ar.Memo,
	  ( CASE WHEN (AR.AmountId = 1  AND AR.Value = @TotalCost)
					OR (AR.AmountId = 2 AND AR.Value != @TotalCost)
					OR (AR.AmountId = 3 AND @TotalCost >=  AR.Value)
					OR (AR.AmountId = 4 AND @TotalCost <= AR.Value)
					OR (AR.AmountId = 5 AND @TotalCost BETWEEN AR.LowerValue AND AR.UpperValue) THEN
					''
			 ELSE
					(CASE WHEN AR.AmountId = 1 THEN
						@TotalCostText + ' is ' +  CONVERT(varchar, CAST(@TotalCost AS money), 1) + ' out of Range.'
						WHEN AR.AmountId = 2 THEN
						 @TotalCostText + ' is '  +  CONVERT(varchar, CAST(@TotalCost AS money), 1) + ' out of Range.'
						WHEN AR.AmountId = 3 THEN
						  @TotalCostText + ' of ' +  CONVERT(varchar, CAST(@TotalCost AS money), 1) + ' exceeds upper Limit of ' + CONVERT(varchar, CAST(AR.Value AS money), 1)
						WHEN AR.AmountId = 4 THEN
						    @TotalCostText + ' of ' +  CONVERT(varchar, CAST(@TotalCost AS money), 1) + ' exceeds lower Limit of ' + CONVERT(varchar, CAST(AR.Value AS money), 1)
						WHEN AR.AmountId = 5 THEN
						    @TotalCostText + ' of ' +  CONVERT(varchar, CAST(@TotalCost AS money), 1) + ' is out of range ' +  CONVERT(varchar, CAST(AR.LowerValue AS money), 1) + ' - ' + CONVERT(varchar, CAST(AR.UpperValue AS money), 1)
                        ELSE
						'Exceeds the approval limit'
						END)END) as  Message,
	   CASE WHEN (AR.AmountId = 1  AND AR.Value = @TotalCost)
					OR (AR.AmountId = 2 AND AR.Value != @TotalCost)
					OR (AR.AmountId = 3 AND @TotalCost >=  AR.Value)
					OR (AR.AmountId = 4 AND @TotalCost <= AR.Value)
					OR (AR.AmountId = 5 AND @TotalCost BETWEEN AR.LowerValue AND AR.UpperValue) THEN					
					CAST(0 AS bit)
			 ELSE
			        CAST(1 AS bit)
	   END as IsExceeded,
	    STUFF((SELECT  Distinct ',' + ISNULL(E.Email,'')
            FROM dbo.ApprovalRule AR  WITH(NOLOCK)
				INNER JOIN dbo.Employee E  WITH(NOLOCK) on Ar.ApproverId = E.EmployeeId
				INNER JOIN dbo.EmployeeManagementStructure EMS   WITH(NOLOCK)
		        on EMS.EmployeeId = E.EmployeeId AND EMS.ManagementStructureId = Ar.ManagementStructureId
				Where ApprovalTaskId = @TaskId
				AND AR.IsActive = 1 AND AR.IsDeleted = 0
				AND AR.ApproverId != @EID
				AND AR.MasterCompanyId = @MasterCompanyID
				AND ISNULL(E.Email,'') != ''
        FOR XML PATH('')), 1, 1, '') AS ApproverEmails
	   from dbo.ApprovalRule AR  WITH(NOLOCK)
	     INNER JOIN dbo.Employee E  WITH(NOLOCK) on Ar.ApproverId = E.EmployeeId
		 INNER JOIN dbo.EmployeeManagementStructure EMS   WITH(NOLOCK)
		            on EMS.EmployeeId = E.EmployeeId AND EMS.ManagementStructureId = Ar.ManagementStructureId
		 Where ApprovalTaskId = @TaskId
			   AND AR.IsActive = 1 AND AR.IsDeleted = 0
			   AND AR.managementStructureId > 0
			  AND AR.ApproverId != @EID
			  AND  AR.MasterCompanyId = @MasterCompanyID
			 AND @MSID IN (SELECT ManagementStructureId FROM #ARMSID )

END TRY	
BEGIN CATCH

IF OBJECT_ID(N'tempdb..#ARMSID') IS NOT NULL
BEGIN
DROP TABLE #ARMSID 
END

	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'usp_GetApprovalListByTaskId'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@MSID, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@ID, '') as Varchar(100)) 		
	,@ApplicationName VARCHAR(100) = 'PAS'

	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
	,@AdhocComments = @AdhocComments
	,@ProcedureParameters = @ProcedureParameters
	,@ApplicationName = @ApplicationName
	,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

	RETURN (1);

	END CATCH	

	IF OBJECT_ID(N'tempdb..#ARMSID') IS NOT NULL
	BEGIN
		DROP TABLE #ARMSID 
	END
END