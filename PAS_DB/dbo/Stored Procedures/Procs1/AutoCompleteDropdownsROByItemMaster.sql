

/*************************************************************           
 ** File:   [AutoCompleteDropdownsAsset]           
 ** Author:  Subhash Saliya 
 ** Description: This stored procedure is used retrieve Asset List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   12/29/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2020   Subhash Saliya Created
	2    06/19/2026  Abhishek Jirawla  Adding IsPiecePart condition in RepairOrderPart table 
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
--EXEC [AutoCompleteDropdownsAsset] '',1,200,'108,109,11'
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsROByItemMaster]
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

		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count = '20';	
		END	
		
		SELECT DISTINCT TOP 20 
						 ro.RepairOrderId as value,
                         ro.RepairOrderNumber as label
					FROM dbo.RepairOrder ro WITH(NOLOCK) 
                     JOIN dbo.RepairOrderPart rop WITH(NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId and rop.ItemTypeId=1 AND ISNULL(ROP.[IsPiecePart], 0) = 0
					 JOIN dbo.ItemMaster im WITH(NOLOCK) ON im.ItemMasterId = rop.ItemMasterId
					WHERE (ro.IsActive = 1 AND ISNULL(ro.IsDeleted,0) = 0 AND (im.ItemMasterId = @itemmasterid)
						AND (ro.RepairOrderNumber LIKE @StartWith + '%') )
		 AND ISNULL(im.IsNonStock,0) = 0 UNION     
		SELECT DISTINCT  
			             ro.RepairOrderId as value,
                         ro.RepairOrderNumber as label
					FROM dbo.RepairOrder ro WITH(NOLOCK) 
                    JOIN dbo.RepairOrderPart rop WITH(NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId and rop.ItemTypeId=1 AND ISNULL(ROP.[IsPiecePart], 0) = 0
					JOIN dbo.ItemMaster im WITH(NOLOCK) ON im.ItemMasterId = rop.ItemMasterId
					WHERE ro.RepairOrderId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				 AND ISNULL(im.IsNonStock,0) = 0 ORDER BY RepairOrderNumber

	END TRY 
	BEGIN CATCH 
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsROByItemMaster'               
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