/*************************************************************           
 ** File:   [GetRepairOrderFreightList]           
 ** Author: Deep Patel
 ** Description: This stored procedure is used to Get Purchase Order Freight List Details
 ** Purpose:         
 ** Date:   11/10/2022
 ** PARAMETERS: @CreditMemoHeaderId bigint 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11/10/2022  Deep Patel     Created
	2    07/08/2024  Shrey Chandegara Updated for change history order.
	3    10/03/2025  Sahdev Saliya  Added a case to get timeZone

-- EXEC GetRepairOrderFreightList 8,0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetRepairOrderFreightList]
@RepairOrderId bigint,
@IsDeleted bit,
@Opr int,
@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
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
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
	IF(@Opr=1)
	BEGIN
	SELECT [RepairOrderFreightId]
          ,[RepairOrderId]
          ,[RepairOrderPartRecordId]
          ,[ItemMasterId]
          ,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          --,[CreatedDate]
		  ,case when CAST(CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate
          --,[UpdatedDate]
		  ,case when CAST(UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
          ,[IsActive]
          ,[IsDeleted]
		  ,[LineNum]
		  ,[ManufacturerId]
		  ,[Manufacturer]
      FROM [dbo].[RepairOrderFreight] WITH (NOLOCK) WHERE RepairOrderId=@RepairOrderId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT [RepairOrderFreightId]
          ,[RepairOrderId]
          ,[RepairOrderPartRecordId]
          ,[ItemMasterId]
          ,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          --,[CreatedDate]
		  ,case when CAST(CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate
          --,[UpdatedDate]
		  ,case when CAST(UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
          ,[IsActive]
          ,[IsDeleted]
		  ,[LineNum]
		  ,[ManufacturerId]
		  ,[Manufacturer]
      FROM [dbo].[RepairOrderFreightAudit] WITH (NOLOCK) WHERE [RepairOrderFreightId]=@RepairOrderId ORDER BY RepairOrderFreightAuditId DESC;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetRepairOrderFreightList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100))			   
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