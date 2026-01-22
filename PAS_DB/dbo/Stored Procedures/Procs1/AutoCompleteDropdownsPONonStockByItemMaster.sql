/*************************************************************           
 ** File:   [AutoCompleteDropdownsPONonStockByItemMaster]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Po List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   02/08/2022       
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/08/2022   Subhah Saliya Created
     
--EXEC [AutoCompleteDropdownsPONonStockByItemMaster] '',1,200,'108,109,11',1
**************************************************************/

Create PROCEDURE [dbo].[AutoCompleteDropdownsPONonStockByItemMaster]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@itemmasterid bigint = '0',
@MasterCompanyId bigint
AS
BEGIN
	  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      SET NOCOUNT ON
	  BEGIN TRY
	    DECLARE @StockType int = 2;
		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count='20';	
		END	
				SELECT DISTINCT TOP 20 
						 po.PurchaseOrderId as value,
                         po.PurchaseOrderNumber as label
					FROM  dbo.PurchaseOrder po WITH(NOLOCK) 
                    JOIN  dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ItemTypeId = @StockType
					WHERE po.MasterCompanyId = @MasterCompanyId AND (po.IsActive=1 AND ISNULL(po.IsDeleted,0) = 0 AND (pop.ItemMasterId = @itemmasterid)
						AND (po.PurchaseOrderNumber LIKE @StartWith + '%'))
			   UNION     
					SELECT DISTINCT  
						 po.PurchaseOrderId as value,
                         po.PurchaseOrderNumber as label
					FROM  dbo.PurchaseOrder po WITH(NOLOCK) 
                    JOIN  dbo.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.ItemTypeId = @StockType
					WHERE po.PurchaseOrderId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				ORDER BY PurchaseOrderNumber

	END TRY 
	BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsPONonStockByItemMaster'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@itemmasterid, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  	
													
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