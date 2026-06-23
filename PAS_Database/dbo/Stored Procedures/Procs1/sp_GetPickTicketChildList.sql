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
	
	-- EXEC [dbo].[sp_GetPickTicketChildList] 1271, 10, 7
**************************************************************/
CREATE  Procedure [dbo].[sp_GetPickTicketChildList]
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

		SELECT DISTINCT sopt.SOPickTicketNumber, 
		                --sopt.QtyToShip, 
						ISNULL(CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopt.QtyToShip,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopt.QtyToShip,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sopt.MasterCompanyId) END,0) AS QtyToShip,
					    sl.SerialNumber, 
					    sl.StockLineNumber,
						CASE WHEN CAST(sopt.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(sopt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END PickedDate,
						CONCAT(emp.FirstName, ' ', emp.LastName) AS PickedBy, 
						sopt.SOPickTicketId, 
						sopt.SalesOrderId, 
						sopt.SalesOrderPartId, 
						stk.SalesOrderStocklineId,
						CONCAT(empy.FirstName, ' ', empy.LastName) AS ConfirmedBy, 
						sl.ControlNumber, 
						sl.IdNumber,						
						CASE WHEN CAST(sopt.ConfirmedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(sopt.ConfirmedDate, @CurrntEmpTimeZoneDesc) AS DATE))END ConfirmedDate,
						sl.StockLineId,
						sopt.IsConfirmed 
				  FROM [dbo].[SOPickTicket] sopt WITH(NOLOCK)
				 INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON sop.SalesOrderId = sopt.SalesOrderId  AND sop.SalesOrderPartId = sopt.SalesOrderPartId
				  LEFT JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
				  LEFT JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON sl.StockLineId = stk.StockLineId
				 INNER JOIN [dbo].[Employee] emp WITH(NOLOCK) ON emp.EmployeeId = sopt.PickedById
				  LEFT JOIN [dbo].[Employee] empy WITH(NOLOCK) ON empy.EmployeeId = sopt.ConfirmedById
				 WHERE sopt.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId
	
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