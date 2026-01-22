/*************************************************************           
 ** File:   [AutoCompleteDropdownStockAdjustment]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used retrieve StockLineAdjustmentType for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   15/04/2024      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/04/2024   AMIT GHEDIYA		Created
     
--EXEC [AutoCompleteDropdownStockAdjustment] 'View_StockLineAdjustmentType'
**************************************************************/
CREATE     PROCEDURE [dbo].[AutoCompleteDropdownStockAdjustment]
	@tableName VARCHAR(50)
AS
	BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
				SELECT 
					SAT.StockLineAdjustmentTypeId AS Value,
					SAT.ToolTip AS ToolTip,
					SAT.Name AS Label
				FROM dbo.View_StockLineAdjustmentType SAT WITH(NOLOCK) 	
		END TRY    
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownStockAdjustment'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@tableName, '') as varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
END