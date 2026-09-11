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
	3    08/01/2026   Moin Bloch	  Update (Added UOM Changes)
    4	 19/06/2026	  Ayushi		  [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	5    09/July/2026   Rajesh Gami       [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	6    20/July/2026   RAJESH GAMI    [PN-17350] - Removed IsNonStock=0 filters so Non-Stock parts appear on the pick ticket.
	7    24/Aug/2026   Kishor Makwana [PN-17439] - Added @SalesOrderPartId in Parameter
	-- EXEC [dbo].[sp_GetPickTicketChildList] 1271, 10, 7
**************************************************************/
CREATE  Procedure [dbo].[sp_GetPickTicketChildList]
	@SalesOrderId  bigint,
	@ItemMasterId bigint,
	@ConditionId bigint,
	@EmployeeId bigint,
	@SalesOrderPartId bigint
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
		LEFT JOIN DBO.StockLine sl WITH(NOLOCK) on sl.StockLineId = stk.StockLineId
		INNER JOIN DBO.Employee emp WITH(NOLOCK) on emp.EmployeeId = sopt.PickedById
		LEFT JOIN DBO.Employee empy WITH(NOLOCK) on empy.EmployeeId = sopt.ConfirmedById
		WHERE sopt.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId AND sop.SalesOrderPartId = @SalesOrderPartId
	
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
			 ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))
												 + '@Parameter2 = ''' + CAST(ISNULL(@ItemMasterId, '') AS VARCHAR(100)) 
												 + '@Parameter3 = ''' + CAST(ISNULL(@ConditionId, '') AS VARCHAR(100)) 
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