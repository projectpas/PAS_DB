/*************************************************************
 ** File:   [sp_GetROPickTicketApproveList]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to retrieve ro pick ticket listing data
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    04/14/2025   Vishal Suthar		Created
	2    06/04/2025   Vishal Suthar		If approval is enforced then pick ticket list will be visible only after approval of the part
	3    07/07/2025   Abhishek Jirawla	RO Piece Parts do not need approval
     
-- EXEC [dbo].[sp_GetROPickTicketApproveList] 2651
**************************************************************/
CREATE   Procedure [dbo].[sp_GetROPickTicketApproveList]
	@RepairOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	DECLARE @ApprovalStatusId INT = 0;
	SELECT @ApprovalStatusId = ApprovalStatusId FROM ApprovalStatus WHERE Name = 'Approved'

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT 
			rop.RepairOrderPartRecordId as RepairOrderPartId, 
			rop.RepairOrderId as RepairOrderId,
			imt.PartNumber as 'PartNumber',
			imt.PartDescription as 'PartDescription', 
			rop.QuantityOrdered as Qty,
			sl.SerialNumber AS 'SerialNumber', 
			sl.QuantityAvailable, 
			ro.RepairOrderNumber as RepairOrderNumber, 
			''  as OrderQuoteNumber
			,SUM(ISNULL(ropt.QtyToShip,0))as QtyToShip,
			CASE WHEN sl.isSerialized = 1 THEN (1 - SUM(ISNULL(ropt.QtyToShip,0))) 
			ELSE (rop.QuantityOrdered - SUM(ISNULL(ropt.QtyToShip,0))) END as QtyToPick,
			CASE WHEN rop.QuantityOrdered = SUM(ropt.QtyToShip) THEN 'Fulfilled'
			ELSE 'Fullfillng' END as [Status],
            rop.ItemMasterId As ItemMasterId,
			sl.ConditionId, 
			(rop.QuantityOrdered - SUM(ISNULL(ropt.QtyToShip,0))) as ReadyToPick, 
			(rop.QuantityOrdered - SUM(ISNULL(ropt.QtyToShip,0))) as TotalReadyToPick, 
			cr.[VendorName] AS VendorName, 
			cr.VendorCode
		FROM DBO.RepairOrderPart rop WITH (NOLOCK)
			INNER JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = rop.ItemMasterId
			LEFT JOIN DBO.StockLine sl WITH (NOLOCK) on sl.StockLineId = rop.StockLineId
			LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) on ro.RepairOrderId = rop.RepairOrderId
			LEFT JOIN DBO.Vendor cr WITH (NOLOCK) on cr.VendorId = ro.VendorId
			LEFT JOIN DBO.RepairOrderApproval roa WITH (NOLOCK) ON roa.RepairOrderPartId = rop.RepairOrderPartRecordId
			LEFT JOIN DBO.ROPickTicket ropt WITH (NOLOCK) on ropt.RepairOrderId = rop.RepairOrderId and ropt.RepairOrderPartId = rop.RepairOrderPartRecordId
		WHERE rop.IsParent = 1 AND
		rop.RepairOrderId = @RepairOrderId AND (rop.QuantityReserved > 0)
		AND (
			ro.IsEnforce IS NULL OR ro.IsEnforce = 0
			OR (ro.IsEnforce = 1 AND roa.StatusId = @ApprovalStatusId)
			OR (ISNULL(rop.IsPiecePart, 0) = 1)
		)
		GROUP BY rop.RepairOrderPartRecordId, rop.RepairOrderId,imt.PartNumber,imt.PartDescription, rop.QuantityOrdered,sl.SerialNumber,
		sl.QuantityAvailable,ro.RepairOrderNumber,rop.ItemMasterId,sl.ConditionId,cr.[VendorName],cr.VendorCode,sl.isSerialized;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetROPickTicketApproveList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END