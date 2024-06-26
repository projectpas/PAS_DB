/*************************************************************               
 ** File:   [CreateStocklineForFinishGoodMPN]               
 ** Author:   Hemant Saliya    
 ** Description: This stored procedure is used Get Stockline For Expired Stockline.        
 ** Purpose:             
 ** Date:   05/23/2023            
              
 ** PARAMETERS:               
 @UserType varchar(60)       
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author  Change Description                
 ** --   --------     -------  --------------------------------              
    1    05/23/2023   Hemant Saliya  Created 
    
-- EXEC [Get_ExpireStockList] 947    
**************************************************************/    
    
CREATE    PROCEDURE [dbo].[Get_ExpireStockList]    
@PageNumber int = NULL,    
@PageSize int = NULL,    
@SortColumn varchar(50)=NULL,    
@SortOrder int = NULL,    
@GlobalFilter varchar(50) = NULL,    
@StocklineNumber varchar(50) = NULL,    
@PartNumber varchar(50) = NULL,    
@PartDescription varchar(50) = NULL,    
@ReceivedDate datetime = NULL,    
@TagDate datetime = NULL,    
@ExpirationDate datetime = NULL,    
@Manufacturer varchar(50) = NULL,    
@CreatedDate  datetime = NULL,    
@EmployeeId BIGINT=NULL,    
@MasterCompanyId BIGINT = NULL,    
@expDate datetime = NULL,    
@expDays  varchar(50)=null,    
@MSModuelId BIGINT = NULL,    
@Site  varchar(50)=null,    
@Warehouse  varchar(50)=null,    
@Location  varchar(50)=null,    
@Shelf  varchar(50)=null,    
@Bin  varchar(50)=null,   
@FromExpiratioDate datetime=null,  
@ToExpirationDate datetime=null,
@SerialNumber varchar(50) = null
AS    
BEGIN     
     SET NOCOUNT ON;    
  DECLARE @RecordFrom INT;    
  DECLARE @Count Int;    
  DECLARE @IsActive bit;    
  SET @RecordFrom = (@PageNumber-1)*@PageSize;     
    
  IF (@SortColumn IS NULL OR @SortColumn = 'CreatedDate')    
  BEGIN    
   SET @SortColumn = Upper('ExpirationDate')    
   SET @SortOrder = 1;    
  END     
  ELSE    
  BEGIN     
   Set @SortColumn=Upper(@SortColumn)    
  END     
  --IF (@FromExpiratioDate IS NOT NULL OR @ToExpirationDate IS NOT NULL)    
  --BEGIN    
  -- SET @SortColumn = Upper('expDays')    
  -- SET @SortOrder = -1;    
  --END     
  BEGIN TRY    
     
   BEGIN    
        
     ;WITH Result AS(    
     SELECT DISTINCT stl.StockLineId,        
         (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',    
         (ISNULL(im.PartNumber,'')) 'PartNumber',    
         (ISNULL(im.PartDescription,'')) 'PartDescription',    
         (ISNULL(stl.Manufacturer,'')) 'Manufacturer',      
         (ISNULL(rPart.PartNumber,'')) 'RevisedPN',              
         (ISNULL(stl.ItemGroup,'')) 'ItemGroup',     
         (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',    
         CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',    
         stl.QuantityOnHand  as QuantityOnHandnew,    
         CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',    
         stl.QuantityAvailable  as QuantityAvailablenew,    
         CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',    
         (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',     
         stl.ControlNumber,    
         stl.IdNumber,    
         (ISNULL(stl.Condition,'')) 'Condition',             
         stl.ReceivedDate as 'ReceivedDate',    
         (ISNULL(stl.ShippingReference,'')) 'AWB',           
         stl.ExpirationDate 'ExpirationDate',    
         stl.TagDate 'TagDate',    
         (ISNULL(stl.TaggedByName,'')) 'TaggedByName',    
         (ISNULL(stl.TagType,'')) 'TagType',     
         (ISNULL(stl.TraceableToName,'')) 'TraceableToName',            
         (ISNULL(stl.itemType,'')) 'ItemCategory',    
         im.ItemTypeId,    
         stl.IsActive,                         
         stl.CreatedDate,    
         stl.CreatedBy,    
         stl.PartCertificationNumber,    
         stl.CertifiedBy,   
         stl.CertifiedDate,    
         stl.UpdatedDate,            
         stl.UpdatedBy,    
         CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,    
         stl.ObtainFromName AS obtainFrom,    
         stl.OwnerName AS ownerName,    
         MSD.LastMSLevel,    
         MSD.AllMSlevels    
        ,stl.DaysReceived    
        ,stl.ManufacturingDays    
        ,stl.TagDays    
        ,stl.OpenDays    
        ,stl.Site    
        ,stl.Warehouse    
        ,stl.Location    
        ,stl.Shelf    
        ,stl.Bin    
        ,sts.RedIndicator    
                          ,sts.YellowIndicator    
                          ,sts.GreenIndicator    
                          , DATEDIFF(DAY, GETDATE(),stl.ExpirationDate) as expDays     
        ,stl.ExpirationDate as expDate    
      FROM  StockLine stl WITH (NOLOCK)    
       INNER JOIN ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId     
       left JOIN StocklineSettings sts WITH (NOLOCK) ON sts.MasterCompanyId =@MasterCompanyId     
       INNER JOIN  dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId    
       LEFT JOIN ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId              
       WHERE stl.MasterCompanyId = @MasterCompanyId and (stl.IsDeleted=0 ) and (stl.QuantityOnHand >0 or stl.QuantityAvailable >0 )    
        AND stl.ExpirationDate is not null --((stl.DaysReceived > 0 or stl.ReceivedDate is not null) or (stl.ManufacturingDays > 0 or stl.ExpirationDate is not null) or (stl.TagDays > 0 or stl.TagDate is not null) or (stl.OpenDays > 0))     
      AND stl.IsParent = 1 and Cast(stl.ExpirationDate as date)   >= Cast(@FromExpiratioDate as date)    and Cast(stl.ExpirationDate as date)  <= Cast(@ToExpirationDate as date)     
    ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)    
    SELECT * INTO #TempResults FROM  Result    
     WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR    
      (PartDescription LIKE '%' +@GlobalFilter+'%') OR     
      (Manufacturer LIKE '%' +@GlobalFilter+'%') OR         
      (SerialNumber LIKE '%' +@GlobalFilter+'%') OR         
      (StocklineNumber LIKE '%' +@GlobalFilter+'%') OR         
      (expDate LIKE '%' +@GlobalFilter+'%') OR    
      (expDays LIKE '%' +@GlobalFilter+'%') OR    
      (UpdatedBy LIKE '%' +@GlobalFilter+'%')))
      OR       
      (@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND    
      (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND    
      (ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND    
      (ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND         
      (ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND    
      (ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND         
      (ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND    
      (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND    
      (ISNULL(@expDays,'') ='' OR expDays LIKE '%' + @expDays + '%') AND    
    
      (ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND    
      (ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND    
      (ISNULL(@Location,'') ='' OR [Location] LIKE '%' + @Location + '%') AND    
      (ISNULL(@Shelf,'') ='' OR Shelf LIKE '%' + @Shelf + '%') AND    
      (ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND    
      (ISNULL(@Bin,'') ='' OR Bin LIKE '%' + @Bin + '%') AND    
      (ISNULL(@expDate,'') ='' OR CAST(expDate AS Date)=CAST(@expDate AS date)))
        )    
        SELECT @Count = COUNT(StockLineId) FROM #TempResults       
    
     SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY      
      CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,    
      CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,    
      CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,       
      CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,       
      CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,    
      CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,       
      CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,     
      CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,    
      CASE WHEN (@SortOrder=1  AND @SortColumn='expDate')  THEN expDate END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='expDate')  THEN expDate END DESC,    
      CASE WHEN (@SortOrder=1  AND @SortColumn='Site')  THEN [Site] END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='Site')  THEN [Site] END DESC,     
      CASE WHEN (@SortOrder=1  AND @SortColumn='Warehouse')  THEN Warehouse END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='Warehouse')  THEN Warehouse END DESC,     
      CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,     
      CASE WHEN (@SortOrder=1  AND @SortColumn='Shelf')  THEN Shelf END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='Shelf')  THEN Shelf END DESC,     
      CASE WHEN (@SortOrder=1  AND @SortColumn='Bin')  THEN Bin END ASC,    
      CASE WHEN (@SortOrder=-1 AND @SortColumn='Bin')  THEN Bin END DESC,     
      CASE WHEN (@SortOrder=1 and @SortColumn='expDays')  THEN expDays END ASC,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='expDays')  THEN expDays END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC  
        
     OFFSET @RecordFrom ROWS     
     FETCH NEXT @PageSize ROWS ONLY    
   END    
        
   
    
  END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'    
       
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
    
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'Get_ExpireStockList'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',     
                @Parameter2 = ' + ISNULL(@PageSize,'') + ',     
                @Parameter3 = ' + ISNULL(@SortColumn,'') + ',     
                @Parameter4 = ' + ISNULL(@SortOrder,'') + ',     
                @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ',     
                @Parameter6 = ' + ISNULL(@StocklineNumber,'') + ',     
                @Parameter7 = ' + ISNULL(@PartNumber,'') + ',     
                @Parameter8 = ' + ISNULL(@PartDescription,'') + ',     
                @Parameter9 = ' + ISNULL(CAST(@ReceivedDate AS varchar(20)) ,'') +''',      
                @Parameter10 = ' + ISNULL(CAST(@TagDate AS varchar(20)) ,'') +''',      
                @Parameter11 = ' + ISNULL(CAST(@ExpirationDate AS varchar(20)) ,'') +''',     
                @Parameter12 = ' + ISNULL(@Manufacturer,'') + ',     
                @Parameter13 = ' + ISNULL(CAST(@CreatedDate AS varchar(20)) ,'') +''',    
                @Parameter14 = ' + ISNULL(@EmployeeId,'') + ',     
                @Parameter15 = ' + ISNULL(@MasterCompanyId,'') + ',     
                @Parameter16 = ' + ISNULL(@expDate,'') + ',     
                @Parameter17 = ' + ISNULL(@expDays,'') + ',    
                @Parameter18 = ' + ISNULL(@MSModuelId,'') +'
                @Parameter19 = ' + ISNULL(CAST(@FromExpiratioDate AS varchar(20)) ,'') + ',    
                @Parameter20 = ' + ISNULL(CAST(@ToExpirationDate AS varchar(20)) ,'') + ''    
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