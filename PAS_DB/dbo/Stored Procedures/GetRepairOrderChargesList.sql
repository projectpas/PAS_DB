/*************************************************************           
 ** File:   [GetRepairOrderChargesList]           
 ** Author:  Deep Patel
 ** Description: This stored procedure is used to Get Repair Order Charges List Details
 ** Purpose:         
 ** Date:   12-10-2022
 ** PARAMETERS: @RepairOrderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12-10-2022  Deep Patel     Created
-- EXEC GetRepairOrderChargesList 8,0
************************************************************************/
CREATE PROCEDURE [dbo].[GetRepairOrderChargesList]
@RepairOrderId BIGINT,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT 
	   [RepairOrderChargesId]
      ,[RepairOrderId]
      ,[RepairOrderPartRecordId]
      ,[ChargesTypeId]
      ,[VendorId]
      ,[Quantity]
      ,[MarkupPercentageId]
      ,[Description]
      ,[UnitCost]
      ,[ExtendedCost]
      ,[MasterCompanyId]
      ,[MarkupFixedPrice]
      ,[BillingMethodId]
      ,[BillingAmount]
      ,[BillingRate]
      ,[HeaderMarkupId]
      ,[RefNum]
      ,[CreatedBy]
      ,[UpdatedBy]
      ,[CreatedDate]
      ,[UpdatedDate]
      ,[IsActive]
      ,[IsDeleted]
      ,[HeaderMarkupPercentageId]
      ,[VendorName]
      ,[ChargeName]
      ,[MarkupName]
      ,[ItemMasterId]
      ,[ConditionId]
	  ,[PartNumber]
	  ,[LineNum]
	  ,CASE WHEN BillingMethodId = 1 THEN 'T&M'
	  ELSE 'Actual' END AS 'BillingMethodName'
      FROM [dbo].[RepairOrderCharges] WITH (NOLOCK) WHERE RepairOrderId=@RepairOrderId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT 
	   [RepairOrderChargesId]
      ,[RepairOrderId]
      ,[RepairOrderPartRecordId]
      ,[ChargesTypeId]
      ,[VendorId]
      ,[Quantity]
      ,[MarkupPercentageId]
      ,[Description]
      ,[UnitCost]
      ,[ExtendedCost]
      ,[MasterCompanyId]
      ,[MarkupFixedPrice]
      ,[BillingMethodId]
      ,[BillingAmount]
      ,[BillingRate]
      ,[HeaderMarkupId]
      ,[RefNum]
      ,[CreatedBy]
      ,[UpdatedBy]
      ,[CreatedDate]
      ,[UpdatedDate]
      ,[IsActive]
      ,[IsDeleted]
      ,[HeaderMarkupPercentageId]
      ,[VendorName]
      ,[ChargeName]
      ,[MarkupName]
      ,[ItemMasterId]
      ,[ConditionId]
	  ,[PartNumber]
	  ,[LineNum]
	  ,CASE WHEN BillingMethodId = 1 THEN 'T&M'
	  ELSE 'Actual' END AS 'BillingMethodName'
      FROM [dbo].[RepairOrderChargesAudit] WITH (NOLOCK) WHERE RepairOrderChargesId=@RepairOrderId and ChargeName is not null;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetRepairOrderChargesList' 
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