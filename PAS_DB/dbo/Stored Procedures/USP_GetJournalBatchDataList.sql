/*************************************************************               
 ** File:   [USP_GetJournalBatchDataList]               
 ** Author:   Subhash Saliya    
 ** Description: Get GetJournalBatchDataList       
 ** Purpose:             
 ** Date:    08/10/2022            
              
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author  Change Description                
 ** --   --------     -------  --------------------------------              
    1    08/10/2022   Subhash Saliya Created    
    2    05/09/2023   Bhargav Saliya  Add One Field [UpdatedBy]
 -- exec USP_GetJournalBatchDataList 92,1        
**************************************************************/     
    
    
CREATE    PROCEDURE [dbo].[USP_GetJournalBatchDataList]    
@PageSize int,      
@PageNumber int,      
@SortColumn varchar(50)= null,      
@SortOrder int= null,     
@GlobalFilter varchar(50)=null,    
@StatusID int= null,      
@BatchName varchar(50),    
@EntryDate datetime=null,    
@PostDate datetime=null,    
@AccountingPeriod varchar(50)= null,    
@StatusName varchar(50)=null,    
@JournalTypeName varchar(50)=null,    
@TotalDebit varchar(50)= null,    
@TotalCredit varchar(50)=null,    
@TotalBalance varchar(50)= null,    
@MasterCompanyId int= null,    
@EmployeeId bigint=1,    
@IsDeleted bit= null,    
@CreatedBy varchar(50),
@UpdatedBy varchar(50)
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    
    
      
   DECLARE @RecordFrom int;     
   Declare @IsActive bit = 1      
   Declare @Count Int;      
   SET @RecordFrom = (@PageNumber - 1) * @PageSize;    
    
   if(@GlobalFilter is null)    
   begin    
   set @GlobalFilter='';    
   end    
    
   IF @SortColumn is null      
   Begin      
    Set @SortColumn = 'JournalBatchHeaderId'      
   End       
   Else      
   Begin       
    Set @SortColumn = Upper(@SortColumn)      
   End    
    
   SELECT COUNT(1) OVER () AS NumberOfItems      
          ,JBH.[JournalBatchHeaderId]    
                   ,JBH.[BatchName]    
                   ,JBH.[CurrentNumber]    
                   ,JBH.[EntryDate]    
                   ,JBH.[PostDate]    
                   ,JBH.[AccountingPeriod]    
                   ,JBH.[StatusId]    
                   ,JBH.[StatusName]    
                   ,JBH.[JournalTypeId]    
                   ,JBH.[JournalTypeName]    
                   ,JBH.[TotalDebit]    
                   ,JBH.[TotalCredit]    
                   ,JBH.[TotalBalance]    
                   ,JBH.[MasterCompanyId]    
                   ,JBH.[CreatedBy]    
                   ,JBH.[UpdatedBy]    
                   ,JBH.[CreatedDate]    
                   ,JBH.[UpdatedDate]    
                   ,JBH.[IsActive]    
                   ,JBH.[IsDeleted]    
       ,JBH.[Module]    
        FROM [dbo].[BatchHeader] JBH WITH(NOLOCK)      
        WHERE ((JBH.MasterCompanyId = @MasterCompanyId) AND (JBH.IsDeleted = @IsDeleted) AND (@StatusID=0 or JBH.StatusId = @StatusID))      
         AND (      
        (@GlobalFilter <>'' AND (      
        (JBH.BatchName like '%' +@GlobalFilter+'%') OR      
        (JBH.EntryDate like '%' +@GlobalFilter+'%') OR      
        (PostDate like '%' +@GlobalFilter+'%') OR      
        (AccountingPeriod like '%' +@GlobalFilter+'%') OR      
        (StatusName like '%'+@GlobalFilter+'%') OR      
        (JournalTypeName like '%'+@GlobalFilter+'%') OR      
   ((CAST(TotalDebit AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR     
   ((CAST(TotalCredit AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR     
   ((CAST(TotalBalance AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR     
        (CreatedBy like '%' +@GlobalFilter+'%')  OR
		(UpdatedBy like '%' +@GlobalFilter+'%')
        ))      
        OR         
        (@GlobalFilter='' AND (IsNull(@BatchName,'') ='' OR BatchName like '%' + @BatchName+'%') AND      
   (IsNull(@EntryDate,'') ='' OR Cast(EntryDate as Date)=Cast(@EntryDate as date)) AND      
   (IsNull(@PostDate,'') ='' OR Cast(PostDate as Date)=Cast(@PostDate as date)) AND      
     (IsNull(@AccountingPeriod,'') ='' OR AccountingPeriod like '%' + @AccountingPeriod+'%') AND      
        (IsNull(@StatusName,'') ='' OR StatusName like '%' + @StatusName+'%') AND      
        (IsNull(@JournalTypeName,'') ='' OR JournalTypeName like '%' + @JournalTypeName+'%') AND    
   (IsNull(@TotalDebit,'') ='' OR CAST(TotalDebit AS varchar(20)) like '%' + @TotalDebit+'%' ) AND     
   (IsNull(@TotalCredit,'') ='' OR CAST(TotalCredit AS varchar(20)) like '%' + @TotalCredit+'%' ) AND      
   (IsNull(@TotalBalance,'') ='' OR CAST(TotalBalance AS varchar(20)) like '%' + @TotalBalance+'%') AND     
   (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
   (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%')
        )    
  )      
        ORDER BY        
   CASE WHEN (@SortOrder=1 and @SortColumn='JournalBatchHeaderId')  THEN JournalBatchHeaderId END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='BatchName')  THEN BatchName END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='EntryDate')  THEN EntryDate END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='PostDate')  THEN PostDate END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='AccountingPeriod')  THEN AccountingPeriod END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='StatusName')  THEN StatusName END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalDebit')  THEN CAST(TotalDebit AS varchar(20)) END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalCredit')  THEN CAST(TotalCredit AS varchar(20)) END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalBalance')  THEN CAST(TotalBalance AS varchar(20)) END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,      
        CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,      
      
        CASE WHEN (@SortOrder=-1 and @SortColumn='JournalBatchHeaderId')  THEN JournalBatchHeaderId END Desc,     
        CASE WHEN (@SortOrder=-1 and @SortColumn='BatchName')  THEN BatchName END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='EntryDate')  THEN EntryDate END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='PostDate')  THEN PostDate END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='AccountingPeriod')  THEN AccountingPeriod END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='StatusName')  THEN StatusName END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='JournalTypeName')  THEN JournalTypeName END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalDebit')  THEN CAST(TotalDebit AS varchar(20))  END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalCredit')  THEN CAST(TotalCredit AS varchar(20)) END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalBalance')  THEN CAST(TotalBalance AS varchar(20)) END Desc,      
        CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END Desc,   
        CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END Desc     
            
      
        OFFSET @RecordFrom ROWS       
        FETCH NEXT @PageSize ROWS ONLY     
    
 END TRY        
 BEGIN CATCH    
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'USP_GetJournalBatchDataList'     
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))    
      + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))     
      + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))    
      + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))    
      + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))    
      + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))    
      + '@Parameter7 = ''' + CAST(ISNULL(@BatchName, '') AS varchar(100))    
      + '@Parameter8 = ''' + CAST(ISNULL(@EntryDate, '') AS varchar(100))    
      + '@Parameter9 = ''' + CAST(ISNULL(@PostDate , '') AS varchar(100))    
      + '@Parameter10 = ''' + CAST(ISNULL(@AccountingPeriod , '') AS varchar(100))    
      + '@Parameter11 = ''' + CAST(ISNULL(@StatusName, '') AS varchar(100))    
      + '@Parameter12 = ''' + CAST(ISNULL(@JournalTypeName, '') AS varchar(100))    
     + '@Parameter13 = ''' + CAST(ISNULL(@TotalDebit, '') AS varchar(100))    
     + '@Parameter14 = ''' + CAST(ISNULL(@TotalCredit, '') AS varchar(100))    
     + '@Parameter15 = ''' + CAST(ISNULL(@TotalBalance , '') AS varchar(100))    
     + '@Parameter16 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))    
     + '@Parameter17 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100))     
     + '@Parameter18 = ''' + CAST(ISNULL(@IsDeleted  , '') AS varchar(100))    
     + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100))     
     + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100))     
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