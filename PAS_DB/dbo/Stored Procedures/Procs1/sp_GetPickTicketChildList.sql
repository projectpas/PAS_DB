-- ===== PROCEDURE: [dbo].[sp_GetPickTicketChildList]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs1/sp_GetPickTicketChildList.sql) =====
/*************************************************************           
 ** File:   [sp_GetPickTicketChildList]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Pick ticket child table list
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    10/15/2024   Vishal Suthar Modified SP to get Pick ticket child table list from new SO Part tables
	2    03/03/2025   Ayushi Patel    converted the date into utc (PickedDate , ConfirmedDate) , Added a case to get timeZone
	3    09/July/2026   RAJESH GAMI    [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
	-- EXEC [dbo].[sp_GetPickTicketChildList] 1271, 10, 7
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_GetPickTicketChildList]
	@SalesOrderId  bigint,
	@ItemMasterId bigint,
	@ConditionId bigint,
	@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		SELECT DISTINCT sopt.SOPickTicketNumber, sopt.QtyToShip, sl.SerialNumber, sl.StockLineNumber,
		--CAST(sopt.CreatedDate AS DATE) as PickedDate,
		case when CAST(sopt.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sopt.CreatedDate, @CurrntEmpTimeZoneDesc) as Date))end PickedDate,
		CONCAT(emp.FirstName, ' ', emp.LastName) as PickedBy, sopt.SOPickTicketId, sopt.SalesOrderId, sopt.SalesOrderPartId, stk.SalesOrderStocklineId,
		CONCAT(empy.FirstName, ' ', empy.LastName) as ConfirmedBy, sl.ControlNumber, sl.IdNumber,
		--CAST(sopt.ConfirmedDate AS DATE) AS ConfirmedDate, 
		case when CAST(sopt.ConfirmedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sopt.ConfirmedDate, @CurrntEmpTimeZoneDesc) as Date))end ConfirmedDate,
		sl.StockLineId, sopt.IsConfirmed 
		FROM DBO.SOPickTicket sopt WITH(NOLOCK)
		INNER JOIN DBO.SalesOrderPartV1 sop WITH(NOLOCK) on sop.SalesOrderId = sopt.SalesOrderId  AND sop.SalesOrderPartId = sopt.SalesOrderPartId
		LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH(NOLOCK) on stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
		LEFT JOIN DBO.StockLine sl WITH(NOLOCK) on sl.StockLineId = stk.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
		INNER JOIN DBO.Employee emp WITH(NOLOCK) on emp.EmployeeId = sopt.PickedById
		LEFT JOIN DBO.Employee empy WITH(NOLOCK) on empy.EmployeeId = sopt.ConfirmedById
		WHERE sopt.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @ItemMasterId and sop.ConditionId = @ConditionId
	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetPickTicketChildList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@ItemMasterId,'') + ',
													 @Parameter3 = ' + ISNULL(@ConditionId,'') + ''
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