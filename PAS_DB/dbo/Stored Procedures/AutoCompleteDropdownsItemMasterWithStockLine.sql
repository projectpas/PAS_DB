/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemMaster]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Item Master List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   12/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/23/2020   Hemant Saliya Created
     
--EXEC [AutoCompleteDropdownsItemMasterWithStockLine] '',1,200,'108,109,11'
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterWithStockLine]
@StartWith VARCHAR(50),
@IsActive bit = true,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int
AS
BEGIN
	  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      SET NOCOUNT ON
	  BEGIN TRY

		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count = '20';	
		END	
		IF(@IsActive = 1)
			BEGIN		
					SELECT DISTINCT TOP 20 
						Im.ItemMasterId AS Value, 
						Im.partnumber AS Label
					FROM dbo.ItemMaster Im WITH(NOLOCK) 						
						INNER JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.ItemMasterId = Im.ItemMasterId			
					WHERE (Im.IsActive=1 AND ISNULL(Im.IsDeleted,0)=0 
						  AND SL.QuantityAvailable > 0
					      AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'))    
			   UNION     
					SELECT DISTINCT Im.ItemMasterId AS Value, 
						  Im.partnumber AS Label
					FROM dbo.ItemMaster Im WITH(NOLOCK) 
						 INNER JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.ItemMasterId = Im.ItemMasterId
					WHERE im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				ORDER BY Label				
			End
			ELSE
			BEGIN
				SELECT DISTINCT TOP 20 
						Im.ItemMasterId AS Value, 
						Im.partnumber AS Label
					FROM dbo.ItemMaster Im WITH(NOLOCK) 
						 INNER JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.ItemMasterId = Im.ItemMasterId
				WHERE Im.IsActive = 1
					  AND SL.QuantityAvailable > 0
				      AND ISNULL(Im.IsDeleted,0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE '%' + @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'
				UNION 
				SELECT DISTINCT TOP 20 
						Im.ItemMasterId AS Value,  
						Im.partnumber AS Label
					FROM dbo.ItemMaster Im WITH(NOLOCK)
						 INNER JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.ItemMasterId = Im.ItemMasterId
				WHERE Im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
				ORDER BY Label	
			END		
			
	  END TRY 
	  BEGIN CATCH   	
			  
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemMasterWithStockLine'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
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